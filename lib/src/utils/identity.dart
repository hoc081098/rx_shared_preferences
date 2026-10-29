/// Returns [value] unchanged.
T identity<T>(T value) => value;

/// Returns [raw] unchanged, ignoring the entry's key.
Object? identityEntryDecoder(String _, Object? raw) => raw;
