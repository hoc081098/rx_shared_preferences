/// Returns [value] unchanged.
Object? identity(Object? value) => value;

/// Returns [raw] unchanged, ignoring the entry's key.
Object? identityEntryDecoder(String _, Object? raw) => raw;
