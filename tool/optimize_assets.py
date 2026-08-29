#!/usr/bin/env python3
"""Optimizes the generated art assets and produces every launcher icon.

Run from the project root:

    python3 tool/optimize_assets.py

* Compresses the large AI-generated source images into mobile-friendly ones.
* Generates all Android launcher icons (legacy + adaptive foregrounds).
* Generates the iOS AppIcon set (all required sizes).

Only Pillow is required.
"""

import json

from PIL import Image, ImageDraw, ImageEnhance
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
IMAGES = ROOT / "assets" / "images"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_ASSETS = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"


def load_centered_square(name: str, size: int) -> Image.Image:
    """Loads an image and center-crops it to a square of `size`."""
    img = Image.open(IMAGES / name).convert("RGB")
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    img = img.crop((left, top, left + side, top + side))
    return img.resize((size, size), Image.LANCZOS)


def optimize_sources() -> None:
    # Wood texture: keep 1024x1024 detail but compress hard (it is drawn
    # darkened and small on the board).
    wood = Image.open(IMAGES / "board_wood.png").convert("RGB")
    wood.save(IMAGES / "board_wood.jpg", "JPEG", quality=88, optimize=True)
    (IMAGES / "board_wood.png").unlink()

    pattern = Image.open(IMAGES / "bg_pattern.png").convert("RGB")
    pattern = pattern.resize((1024, 1024), Image.LANCZOS)
    pattern.save(IMAGES / "bg_pattern.jpg", "JPEG", quality=82, optimize=True)
    (IMAGES / "bg_pattern.png").unlink()

    # Logo: keep crisp RGB, moderate compression.
    logo = Image.open(IMAGES / "logo.png").convert("RGB")
    logo.save(IMAGES / "logo.jpg", "JPEG", quality=90, optimize=True)
    (IMAGES / "logo.png").unlink()


def rounded_icon(img: Image.Image, radius_ratio: float = 0.22) -> Image.Image:
    """Returns the icon with rounded corners on a transparent background."""
    size = img.size[0]
    radius = int(size * radius_ratio)
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def generate_android_icons() -> None:
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    adaptive_sizes = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }

    base = load_centered_square("icon_source.png", 512)
    base = ImageEnhance.Contrast(base).enhance(1.04)

    # Legacy square (rounded) + round icons.
    for folder, size in densities.items():
        target = ANDROID_RES / folder
        target.mkdir(parents=True, exist_ok=True)
        icon = rounded_icon(base.resize((size, size), Image.LANCZOS))
        icon.save(target / "ic_launcher.png", "PNG", optimize=True)

        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, size, size), fill=255)
        round_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        round_img.paste(base.resize((size, size), Image.LANCZOS), (0, 0), mask)
        round_img.save(target / "ic_launcher_round.png", "PNG", optimize=True)

    # Adaptive icon foregrounds: artwork shrunk into the 66% safe zone.
    for folder, size in adaptive_sizes.items():
        target = ANDROID_RES / folder
        target.mkdir(parents=True, exist_ok=True)
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        inner = int(size * 0.62)
        art = base.resize((inner, inner), Image.LANCZOS)
        offset = (size - inner) // 2
        canvas.paste(art, (offset, offset))
        canvas.save(target / "ic_launcher_foreground.png", "PNG", optimize=True)


# (filename, pixel size, idiom, scale, point size)
IOS_ICON_SPECS = [
    ("icon-20.png", 20, "ipad", 1, 20),
    ("icon-20@2x.png", 40, "iphone", 2, 20),
    ("icon-20@2x-1.png", 40, "ipad", 2, 20),
    ("icon-20@3x.png", 60, "iphone", 3, 20),
    ("icon-29.png", 29, "ipad", 1, 29),
    ("icon-29@2x.png", 58, "iphone", 2, 29),
    ("icon-29@2x-1.png", 58, "ipad", 2, 29),
    ("icon-29@3x.png", 87, "iphone", 3, 29),
    ("icon-40.png", 40, "ipad", 1, 40),
    ("icon-40@2x.png", 80, "iphone", 2, 40),
    ("icon-40@2x-1.png", 80, "ipad", 2, 40),
    ("icon-40@3x.png", 120, "iphone", 3, 40),
    ("icon-60@2x.png", 120, "iphone", 2, 60),
    ("icon-60@3x.png", 180, "iphone", 3, 60),
    ("icon-76.png", 76, "ipad", 1, 76),
    ("icon-76@2x.png", 152, "ipad", 2, 76),
    ("icon-83.5@2x.png", 167, "ipad", 2, 83.5),
    ("icon-1024.png", 1024, "ios-marketing", 1, 1024),
]


def generate_ios_icons() -> None:
    IOS_ASSETS.mkdir(parents=True, exist_ok=True)
    base = load_centered_square("icon_source.png", 1024)
    base = ImageEnhance.Contrast(base).enhance(1.04)

    images_json = []
    for filename, size, idiom, scale, points in IOS_ICON_SPECS:
        base.resize((size, size), Image.LANCZOS).save(
            IOS_ASSETS / filename, "PNG", optimize=True
        )
        images_json.append(
            {
                "filename": filename,
                "idiom": idiom,
                "scale": f"{scale}x",
                "size": f"{points}x{points}",
            }
        )

    contents = {"images": images_json, "info": {"author": "xcode", "version": 1}}
    (IOS_ASSETS / "Contents.json").write_text(
        json.dumps(contents, indent=2), encoding="utf-8"
    )


def main() -> None:
    optimize_sources()
    generate_android_icons()
    generate_ios_icons()
    print("assets optimized; icons generated.")


if __name__ == "__main__":
    main()
