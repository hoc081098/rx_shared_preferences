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

  ///
  /// Construct a [KeyAndValue] from a [MapEntry]
  ///
  factory KeyAndValue.fromMapEntry(MapEntry<String, T> mapEntry) =>
      KeyAndValue(mapEntry.key, mapEntry.value);

  @override
  String toString() => "{ '$key': $value }";
}
