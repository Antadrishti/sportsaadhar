/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String name;
  final double score;
  final int rank;
  final int? level;
  final String? profileImage;
  final int? percentile;
  final String? rating;
  final String? state;
  final int? age;
  final String? gender;
  final DateTime? date;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.score,
    required this.rank,
    this.level,
    this.profileImage,
    this.percentile,
    this.rating,
    this.state,
    this.age,
    this.gender,
    this.date,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      name: json['name'] as String,
      score: (json['score'] is int)
          ? (json['score'] as int).toDouble()
          : (json['score'] as double? ?? 0.0),
      rank: json['rank'] as int,
      level: json['level'] as int?,
      profileImage: json['profileImage'] as String?,
      percentile: json['percentile'] as int?,
      rating: json['rating'] as String?,
      state: json['state'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'score': score,
      'rank': rank,
      if (level != null) 'level': level,
      if (profileImage != null) 'profileImage': profileImage,
      if (percentile != null) 'percentile': percentile,
      if (rating != null) 'rating': rating,
      if (state != null) 'state': state,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (date != null) 'date': date!.toIso8601String(),
    };
  }

  bool get isTopThree => rank <= 3;
  
  String get rankDisplay {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }
}

/// Complete leaderboard data with top users and user position
class LeaderboardData {
  final LeaderboardType type;
  final List<LeaderboardEntry> topUsers;
  final LeaderboardEntry? userPosition;
  final int totalUsers;
  final String? filterValue; // state, ageGroup, gender, or testId

  const LeaderboardData({
    required this.type,
    required this.topUsers,
    this.userPosition,
    required this.totalUsers,
    this.filterValue,
  });

  factory LeaderboardData.fromJson(Map<String, dynamic> json) {
    return LeaderboardData(
      type: _parseLeaderboardType(json['type'] as String?),
      topUsers: (json['topUsers'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userPosition: json['userPosition'] != null
          ? LeaderboardEntry.fromJson(json['userPosition'] as Map<String, dynamic>)
          : null,
      totalUsers: json['totalUsers'] as int? ?? 0,
      filterValue: json['state'] as String? ?? 
                   json['ageGroup'] as String? ?? 
                   json['gender'] as String? ?? 
                   json['testId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'topUsers': topUsers.map((e) => e.toJson()).toList(),
      if (userPosition != null) 'userPosition': userPosition!.toJson(),
      'totalUsers': totalUsers,
      if (filterValue != null) 'filterValue': filterValue,
    };
  }

  static LeaderboardType _parseLeaderboardType(String? type) {
    switch (type?.toLowerCase()) {
      case 'global':
        return LeaderboardType.global;
      case 'regional':
        return LeaderboardType.regional;
      case 'agegroup':
      case 'age_group':
        return LeaderboardType.ageGroup;
      case 'gender':
        return LeaderboardType.gender;
      case 'test':
        return LeaderboardType.test;
      default:
        return LeaderboardType.global;
    }
  }

  bool get userInTopUsers => topUsers.any((entry) => 
      userPosition != null && entry.userId == userPosition!.userId);
}

/// Leaderboard type enum
enum LeaderboardType {
  global,
  regional,
  ageGroup,
  gender,
  test,
}

/// User ranks across all leaderboard types
class UserRanks {
  final int? global;
  final int? regional;
  final int? ageGroup;
  final int? gender;

  const UserRanks({
    this.global,
    this.regional,
    this.ageGroup,
    this.gender,
  });

  factory UserRanks.fromJson(Map<String, dynamic> json) {
    return UserRanks(
      global: json['global'] as int?,
      regional: json['regional'] as int?,
      ageGroup: json['ageGroup'] as int?,
      gender: json['gender'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (global != null) 'global': global,
      if (regional != null) 'regional': regional,
      if (ageGroup != null) 'ageGroup': ageGroup,
      if (gender != null) 'gender': gender,
    };
  }

  int? getBest() {
    final ranks = [global, regional, ageGroup, gender].whereType<int>();
    return ranks.isEmpty ? null : ranks.reduce((a, b) => a < b ? a : b);
  }
}


