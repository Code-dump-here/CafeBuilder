/// How VND amounts are written, everywhere.
///
/// This exists because the app had grown six different answers to "render this
/// amount", and the seams between them were visible to the user: a project's
/// budget read `1,500,000 VND` on the detail page and the payment batch one tap
/// later read `1.500.000 VND`, because one screen grouped with commas and the
/// other used `NumberFormat.decimalPattern('vi_VN')`, which groups with dots.
/// Two more screens — the OTP signing page and the collaboration workspace —
/// printed the raw digits with no grouping at all, so a contract worth a
/// billion dong appeared as `1000000000 VND` on the screen where the owner
/// commits to paying it.
///
/// A formatter is a decision about how money reads, not a per-page detail, so
/// there is one of them and it lives here.
///
/// These are top-level functions rather than a `NumberFormat` instance on
/// purpose. The old code threaded a formatter object down through widget
/// constructors — four classes in the payment batches page alone carried a
/// `final NumberFormat money` field for no reason other than to hand it to
/// their children. Rendering money does not depend on any state, so nothing
/// needs to be passed anywhere.
library;

/// Thousands separator.
///
/// Comma, matching the rest of the interface: every label in the owner app is
/// in English, and [formatVndCompact] already spends the dot on the decimal in
/// `1.5M VND` — grouping with dots too would make the same character mean two
/// different things in amounts sitting next to each other.
///
/// Vietnamese convention is the other way round (`1.500.000 ₫`). If the app is
/// ever translated, this is the line to change, and changing it here changes
/// every amount in the app at once. That is the point of this file.
const String _groupSeparator = ',';

/// Written after the amount, the way the app has always written it.
const String _currencySuffix = 'VND';

/// Inserts [_groupSeparator] every three digits from the right.
///
/// Takes a bare digit string — sign and suffix are the callers' business,
/// because a `-` on the front would otherwise be counted as a digit and push
/// every separator one place over.
String _group(String digits) => digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}$_groupSeparator',
    );

/// The full amount: `1,500,000 VND`.
///
/// Use this wherever the exact figure matters — contracts, quotations, payment
/// batches, anything the user might check against a bank transfer.
///
/// Rounded to whole dong. VND has no subunit in practice; the backend sends
/// these as doubles, and `1500000.0000001` coming back off a percentage split
/// is an artefact of the wire format, not a real amount.
String formatVnd(num amount) => '${formatVndDigits(amount)} $_currencySuffix';

/// The grouped digits alone, with no currency suffix: `1,500,000`.
///
/// For text fields the user types into, and for anywhere the surrounding
/// sentence already says what the currency is.
String formatVndDigits(num amount) {
  final rounded = amount.round();
  final sign = rounded < 0 ? '-' : '';
  return '$sign${_group(rounded.abs().toString())}';
}

/// The abbreviated amount: `1.5M VND`, `250k VND`.
///
/// For cards and list rows, where the full figure would wrap or crowd out the
/// label next to it. Never use it where the user is being asked to approve or
/// pay the amount — `1.5M VND` is not a number anyone can check.
///
/// The billions tier is not optional. Budgets here are VND, so a mid-sized
/// café project is a number in the hundreds of millions and a large one runs
/// past a billion; without `B` those all collapse into a four-digit `M`.
String formatVndCompact(num amount) {
  final value = amount.toDouble();
  final sign = value < 0 ? '-' : '';
  final magnitude = value.abs();

  if (magnitude >= 1000000000) {
    return '$sign${(magnitude / 1000000000).toStringAsFixed(1)}B $_currencySuffix';
  }
  if (magnitude >= 1000000) {
    return '$sign${(magnitude / 1000000).toStringAsFixed(1)}M $_currencySuffix';
  }
  if (magnitude >= 1000) {
    return '$sign${(magnitude / 1000).toStringAsFixed(0)}k $_currencySuffix';
  }
  return '$sign${magnitude.toStringAsFixed(0)} $_currencySuffix';
}

/// Drops a trailing `.0`, and any trailing zero inside the decimals, so a
/// round number reads as a round number.
String _trimDecimals(double value, int maxDecimals) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  final fixed = value.toStringAsFixed(maxDecimals);
  return fixed.contains('.')
      ? fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
      : fixed;
}

/// A percentage, without the sign: `30`, `12.5`.
///
/// Lives here because the payment batches and quotation pages were formatting
/// their percentages with the *money* formatter — harmless while that formatter
/// only inserted separators, and wrong the moment it started appending a
/// currency, which would have rendered a 30% instalment as `30 VND%`.
///
/// A batch is far more often a round 30% than 30.5%, and `30%` is what the
/// provider wrote in the quotation.
String formatPercent(num value) => _trimDecimals(value.toDouble(), 1);

/// A quantity of something that is not money: `12`, `12.5`, `1,200`.
///
/// Separate from [formatVnd] because quantities must not be rounded to whole
/// units — half a square metre of tiling is a real line on a quotation, and
/// rounding it away changes what the line item says was priced.
String formatQuantity(num value) {
  final asDouble = value.toDouble();
  final whole = asDouble.truncate().abs();
  final grouped = _group(whole.toString());
  final trimmed = _trimDecimals(asDouble.abs(), 2);
  final decimals = trimmed.contains('.') ? trimmed.substring(trimmed.indexOf('.')) : '';
  return '${asDouble < 0 ? '-' : ''}$grouped$decimals';
}
