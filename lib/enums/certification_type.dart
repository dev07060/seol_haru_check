enum CertificationType {
  exercise('운동'),
  diet('식단');

  const CertificationType(this.displayName);

  final String displayName;

  static List<String> get displayNames => values.map((e) => e.displayName).toList();

  static CertificationType fromDisplayName(String displayName) {
    return values.firstWhere((e) => e.displayName == displayName);
  }
}
