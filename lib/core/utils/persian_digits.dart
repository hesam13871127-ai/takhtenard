/// Persian (Eastern Arabic) digit helpers.
///
/// All numbers shown in the UI use Persian numerals for an authentic,
/// fully-localized feel.
abstract final class PersianDigits {
  static const List<String> _digits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  /// Converts [input] digits (0-9) to Persian digits; anything else is
  /// passed through unchanged.
  static String convert(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(_digits[rune - 0x30]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Formats an integer with Persian digits.
  static String format(num value) => convert(value.toString());
}
