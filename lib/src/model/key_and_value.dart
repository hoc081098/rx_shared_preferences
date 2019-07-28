///
/// Pair of [key] and [value]
///
class KeyAndValue<T> {
  final String key;
  final T value;

  const KeyAndValue(this.key, this.value);

  @override
  String toString() => "{ '$key': $value }";
}
