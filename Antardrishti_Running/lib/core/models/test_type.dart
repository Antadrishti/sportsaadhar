class TestType {
  final String id;
  final String name;
  final String description;
  final String sport;
  final int recommendedDurationSeconds;

  TestType({
    required this.id,
    required this.name,
    required this.description,
    required this.sport,
    required this.recommendedDurationSeconds,
  });

  factory TestType.fromJson(Map<String, dynamic> json) => TestType(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        sport: json['sport'],
        recommendedDurationSeconds: json['recommendedDurationSeconds'],
      );
}