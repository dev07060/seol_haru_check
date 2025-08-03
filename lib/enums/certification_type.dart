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

/// 운동 세부 카테고리
enum ExerciseCategory {
  strength('근력 운동', '💪'),
  cardio('유산소 운동', '🏃'),
  flexibility('스트레칭/요가', '🧘'),
  sports('구기/스포츠', '⚽'),
  outdoor('야외 활동', '🏔️'),
  dance('댄스/무용', '💃');

  const ExerciseCategory(this.displayName, this.emoji);

  final String displayName;
  final String emoji;

  static List<ExerciseCategory> get all => values;

  static List<String> get displayNames => values.map((e) => e.displayName).toList();

  static ExerciseCategory fromDisplayName(String displayName) {
    return values.firstWhere((e) => e.displayName == displayName);
  }
}

/// 식단 세부 카테고리
enum DietCategory {
  homeMade('집밥/도시락', '🍱'),
  healthy('건강식/샐러드', '🥗'),
  protein('단백질 위주', '🍗'),
  snack('간식/음료', '🍪'),
  dining('외식/배달', '🍽️'),
  supplement('영양제/보충제', '💊');

  const DietCategory(this.displayName, this.emoji);

  final String displayName;
  final String emoji;

  static List<DietCategory> get all => values;

  static List<String> get displayNames => values.map((e) => e.displayName).toList();

  static DietCategory fromDisplayName(String displayName) {
    return values.firstWhere((e) => e.displayName == displayName);
  }
}
