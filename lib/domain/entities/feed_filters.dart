class FeedFilters {
  static const int defaultMinAge = 18;
  static const int defaultMaxAge = 80;

  final int minAge;
  final int maxAge;
  final Set<String> petTypes;

  FeedFilters({
    required int minAge,
    required int maxAge,
    Set<String>? petTypes,
  })  : minAge = _sanitizeMin(minAge, maxAge),
        maxAge = _sanitizeMax(minAge, maxAge),
        petTypes = _normalizePetTypes(petTypes);

  factory FeedFilters.defaults() =>
      FeedFilters(minAge: defaultMinAge, maxAge: defaultMaxAge);

  FeedFilters copyWith({
    int? minAge,
    int? maxAge,
    Set<String>? petTypes,
  }) {
    return FeedFilters(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      petTypes: petTypes ?? this.petTypes,
    );
  }

  bool allowsAge(String rawAge) {
    final age = int.tryParse(rawAge.trim());
    if (age == null) return true;
    return age >= minAge && age <= maxAge;
  }

  bool allowsPetType(String rawType) {
    if (petTypes.isEmpty) return true;
    final normalized = _normalizeValue(rawType);
    if (normalized.isEmpty) return true;
    return petTypes.contains(normalized);
  }

  bool isEquivalentTo(FeedFilters other) {
    if (identical(this, other)) return true;
    if (minAge != other.minAge || maxAge != other.maxAge) return false;
    if (petTypes.length != other.petTypes.length) return false;
    for (final item in petTypes) {
      if (!other.petTypes.contains(item)) return false;
    }
    return true;
  }

  static int _clamp(int value) {
    return value.clamp(defaultMinAge, defaultMaxAge).toInt();
  }

  static int _sanitizeMin(int minValue, int maxValue) {
    final clampedMin = _clamp(minValue);
    final clampedMax = _clamp(maxValue);
    return clampedMin <= clampedMax ? clampedMin : clampedMax;
  }

  static int _sanitizeMax(int minValue, int maxValue) {
    final clampedMin = _clamp(minValue);
    final clampedMax = _clamp(maxValue);
    return clampedMax >= clampedMin ? clampedMax : clampedMin;
  }

  static Set<String> _normalizePetTypes(Set<String>? values) {
    if (values == null || values.isEmpty) {
      return <String>{};
    }
    return {
      for (final value in values)
        if (_normalizeValue(value).isNotEmpty) _normalizeValue(value)
    };
  }

  static String _normalizeValue(String? value) {
    return value?.toLowerCase().trim() ?? '';
  }
}
