/// Deterministic index from an id, for picking a stable image or colour.
///
/// These used to be arithmetic on numeric ids (`id.abs() % n`). Ids are uuids
/// now, so there is no number to take the modulus of — but the requirement is
/// unchanged: the same entity must get the same pick on every rebuild, and
/// different entities should spread across the options rather than clumping.
///
/// FNV-1a is used because it is short, dependency-free, and mixes the
/// low-entropy parts of a uuid well. Using `id.length` or a single char code
/// would put most uuids in the same bucket, since they share a fixed length
/// and a limited alphabet.
int hashId(String? id) {
  if (id == null || id.isEmpty) return 0;

  var hash = 0x811c9dc5;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    // 32-bit FNV prime multiply, masked back into range.
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Stable index into a fixed-length list for an id.
int indexForId(String? id, int length) {
  if (length <= 0) return 0;
  return hashId(id) % length;
}
