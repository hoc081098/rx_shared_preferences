///
/// Pair of [key] and [value].
///
class KeyAndValue<T> {
  ///
  /// The key of the [KeyAndValue].
  ///
  final String key;

  ///
  /// The value associated to [key].
  ///
  final T value;

  ///
  /// Construct a [KeyAndValue] with [key] and [key].
  ///
  const KeyAndValue(this.key, this.value);

  @override
  String toString() => "{ '$key': $value }";
}
