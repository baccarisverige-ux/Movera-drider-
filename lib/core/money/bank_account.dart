/// Checks for payout bank details. Swedish accounts are a clearing number
/// plus an account number; abroad (and in Sweden too) an IBAN plus BIC.
class BankAccountRules {
  const BankAccountRules._();

  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String compact(String value) =>
      value.replaceAll(RegExp(r'\s'), '').toUpperCase();

  // Clearing number ranges of the larger Swedish banks.
  static const List<(int, int, String)> _clearing = [
    (1100, 1199, 'Nordea'),
    (1200, 1399, 'Danske Bank'),
    (1400, 2099, 'Nordea'),
    (2300, 2399, 'Ålandsbanken'),
    (2400, 2499, 'Danske Bank'),
    (3000, 3399, 'Nordea'),
    (3400, 3409, 'Länsförsäkringar Bank'),
    (3410, 4999, 'Nordea'),
    (5000, 5999, 'SEB'),
    (6000, 6999, 'Handelsbanken'),
    (7000, 8999, 'Swedbank'),
    (9020, 9029, 'Länsförsäkringar Bank'),
    (9060, 9069, 'Länsförsäkringar Bank'),
    (9120, 9124, 'SEB'),
    (9130, 9149, 'SEB'),
    (9150, 9169, 'Skandiabanken'),
    (9180, 9189, 'Danske Bank'),
    (9190, 9199, 'DNB'),
    (9250, 9259, 'SBAB'),
    (9270, 9279, 'ICA Banken'),
    (9280, 9289, 'Resurs Bank'),
    (9400, 9449, 'Forex Bank'),
    (9500, 9549, 'Nordea'),
    (9550, 9569, 'Avanza Bank'),
    (9570, 9579, 'Sparbanken Syd'),
    (9660, 9669, 'Svea Bank'),
    (9670, 9679, 'JAK Medlemsbank'),
    (9960, 9969, 'Nordea'),
  ];

  /// The bank for a clearing number, or null when unknown or malformed.
  /// Swedbank's clearing numbers starting with 8 have five digits.
  static String? bankForClearing(String value) {
    final formatted = value.trim();
    if (!RegExp(r'^\d+(?:\s*-\s*\d+|\s+\d+)*$').hasMatch(formatted)) {
      return null;
    }
    final d = digits(formatted);
    final ok = d.startsWith('8') ? d.length == 5 : d.length == 4;
    if (!ok) return null;
    final key = int.parse(d.substring(0, 4));
    for (final (from, to, bank) in _clearing) {
      if (key >= from && key <= to) return bank;
    }
    return null;
  }

  /// Swedish account numbers are 6 to 10 digits after the clearing number.
  static bool validAccount(String value) {
    final formatted = value.trim();
    if (!RegExp(r'^\d+(?:\s*-\s*\d+|\s+\d+)*$').hasMatch(formatted)) {
      return false;
    }
    final d = digits(formatted);
    return d.length >= 6 && d.length <= 10;
  }

  // The 3-digit bank code inside a Swedish IBAN.
  static const Map<String, String> _ibanBanks = {
    '120': 'Danske Bank',
    '300': 'Nordea',
    '500': 'SEB',
    '600': 'Handelsbanken',
    '800': 'Swedbank',
    '902': 'Länsförsäkringar Bank',
    '915': 'Skandiabanken',
    '927': 'ICA Banken',
    '950': 'Nordea',
    '955': 'Avanza Bank',
  };

  /// An IBAN passes when its length fits (24 for Sweden) and mod 97 is 1.
  static bool validIban(String value) {
    final iban = compact(value);
    if (!RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$').hasMatch(iban)) {
      return false;
    }
    if (iban.startsWith('SE') && iban.length != 24) return false;
    final moved = iban.substring(4) + iban.substring(0, 4);
    var rest = 0;
    for (final unit in moved.codeUnits) {
      final n = unit >= 65 ? unit - 55 : unit - 48;
      rest = (n >= 10 ? rest * 100 + n : rest * 10 + n) % 97;
    }
    return rest == 1;
  }

  /// The bank of a valid Swedish IBAN, or the country code for others.
  static String? bankForIban(String value) {
    if (!validIban(value)) return null;
    final iban = compact(value);
    if (!iban.startsWith('SE')) return iban.substring(0, 2);
    return _ibanBanks[iban.substring(4, 7)];
  }

  /// BIC/SWIFT: bank (4) + country (2) + place (2) + optional branch (3).
  static bool validBic(String value) =>
      RegExp(r'^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$').hasMatch(compact(value));
}
