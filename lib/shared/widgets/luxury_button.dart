import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_palette.dart';
import '../../core/audio/sound_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A large luxurious gold button used for primary actions.
class LuxuryButton extends ConsumerWidget {
  const LuxuryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.small = false,
    this.secondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool small;
  final bool secondary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sound = ref.read(soundControllerProvider);
    final theme = Theme.of(context);

    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          sound.play(SoundEffect.click);
          onPressed();
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: secondary
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3A2A20), Color(0xFF241812)],
                  )
                : AppPalette.goldGradient,
            border: Border.all(
              color: secondary ? AppPalette.panelBorder : AppPalette.goldDark,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: secondary
                    ? const Color(0x33000000)
                    : const Color(0x66D4AF37),
                blurRadius: secondary ? 8 : 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 16 : 26,
              vertical: small ? 10 : 16,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: small ? 20 : 26,
                  color: secondary ? AppPalette.gold : AppPalette.darkerBrown,
                ),
                SizedBox(width: small ? 8 : 12),
                Text(
                  label,
                  style: (small
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color:
                            secondary ? AppPalette.ivory : AppPalette.darkerBrown,
                        fontSize: small ? 15 : 19,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return button
        .animate()
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 260.ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// A round icon button in the luxury style.
class LuxuryIconButton extends ConsumerWidget {
  const LuxuryIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sound = ref.read(soundControllerProvider);
    final enabled = this.enabled;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled
                ? () {
                    sound.play(SoundEffect.click);
                    onPressed();
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A2A20), Color(0xFF241812)],
                ),
                border: Border.all(color: AppPalette.panelBorder),
              ),
              child: Icon(icon, size: 22, color: AppPalette.gold),
            ),
          ),
        ),
      ),
    );
  }
}
