/// Integer minor-units money (D6). SEK uses öre. Never store display strings.
class Money {
  const Money({required this.minorUnits, this.currency = 'SEK'});

  factory Money.ore(int ore) => Money(minorUnits: ore);

  factory Money.sek(num kronor) =>
      Money(minorUnits: (kronor * 100).round());

  final int minorUnits;
  final String currency;

  int get ore => minorUnits;

  Money operator +(Money other) {
    _sameCurrency(other);
    return Money(minorUnits: minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    _sameCurrency(other);
    return Money(minorUnits: minorUnits - other.minorUnits, currency: currency);
  }

  /// Swedish display: `104,80 kr` / `2 994,80 kr`.
  String get formatted {
    if (currency != 'SEK') {
      throw UnsupportedError('No formatter for $currency');
    }
    final sign = minorUnits < 0 ? '−' : '';
    final abs = minorUnits.abs();
    final major = abs ~/ 100;
    final minor = (abs % 100).toString().padLeft(2, '0');
    return '$sign${_group(major)},$minor kr';
  }

  void _sameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError.value(other.currency, 'currency', 'mismatch');
    }
  }

  static String _group(int major) {
    final digits = major.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.minorUnits == minorUnits &&
        other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => formatted;
}
