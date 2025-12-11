 class TestResultModel {
  final String? id;
  final String testName;
  final String testType;
  final double distance; // in meters
  final double timeTaken; // in seconds
  final double speed; // in m/s
  final double? pace; // in min/km
  final DateTime date;
  
  // Height test specific fields
  final double? measuredHeight; // in cm (stored but not displayed)
  final double? registeredHeight; // in cm (user's registered height)
  final bool? isHeightVerified; // true if within ±7 cm tolerance
  
  // Jump test specific fields
  final double? jumpHeight; // in cm (vertical or horizontal jump)
  final String? jumpType; // 'vertical', 'broad', etc.
  
  // Exercise repetition fields (sit-ups, push-ups, etc.)
  final int? repsCount; // number of repetitions completed
  final String? exerciseType; // 'situps', 'pushups', etc.
  
  // Flexibility test fields (sit and reach)
  final double? flexibilityAngle; // in degrees (lower = better)
  final String? flexibilityRating; // 'elite', 'excellent', 'very_good', 'good'
  
  // Shuttle run specific fields
  final int? shuttleRunLaps; // Number of laps completed (target: 4)
  final int? directionChanges; // Number of direction changes detected (target: 3)
  final double? averageGpsAccuracy; // Average GPS accuracy in meters

  TestResultModel({
    this.id,
    required this.testName,
    required this.testType,
    required this.distance,
    required this.timeTaken,
    required this.speed,
    this.pace,
    required this.date,
    this.measuredHeight,
    this.registeredHeight,
    this.isHeightVerified,
    this.jumpHeight,
    this.jumpType,
    this.repsCount,
    this.exerciseType,
    this.flexibilityAngle,
    this.flexibilityRating,
    this.shuttleRunLaps,
    this.directionChanges,
    this.averageGpsAccuracy,
  });

  // Calculate pace from speed if not provided
  double get calculatedPace {
    if (pace != null) return pace!;
    if (speed <= 0) return 0;
    return (1000 / speed) / 60; // Convert m/s to min/km
  }

  // Format time as MM:SS or HH:MM:SS
  String get formattedTime {
    final duration = Duration(seconds: timeTaken.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Format distance
  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }

  // Format speed
  String get formattedSpeed {
    return '${speed.toStringAsFixed(2)} m/s';
  }

  // Format pace
  String get formattedPace {
    final paceValue = calculatedPace;
    final minutes = paceValue.floor();
    final seconds = ((paceValue - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} min/km';
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'testName': testName,
      'testType': testType,
      'distance': distance,
      'timeTaken': timeTaken,
      'speed': speed,
      if (pace != null) 'pace': pace,
      'date': date.toIso8601String(),
      if (measuredHeight != null) 'measuredHeight': measuredHeight,
      if (registeredHeight != null) 'registeredHeight': registeredHeight,
      if (isHeightVerified != null) 'isHeightVerified': isHeightVerified,
      if (jumpHeight != null) 'jumpHeight': jumpHeight,
      if (jumpType != null) 'jumpType': jumpType,
      if (repsCount != null) 'repsCount': repsCount,
      if (exerciseType != null) 'exerciseType': exerciseType,
      if (flexibilityAngle != null) 'flexibilityAngle': flexibilityAngle,
      if (flexibilityRating != null) 'flexibilityRating': flexibilityRating,
      if (shuttleRunLaps != null) 'shuttleRunLaps': shuttleRunLaps,
      if (directionChanges != null) 'directionChanges': directionChanges,
      if (averageGpsAccuracy != null) 'averageGpsAccuracy': averageGpsAccuracy,
    };
  }

  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      id: json['id'] as String?,
      testName: (json['testName'] ?? '') as String,
      testType: (json['testType'] ?? 'running') as String,
      distance: (json['distance'] is int)
          ? (json['distance'] as int).toDouble()
          : (json['distance'] ?? 0.0) as double,
      timeTaken: (json['timeTaken'] is int)
          ? (json['timeTaken'] as int).toDouble()
          : (json['timeTaken'] ?? 0.0) as double,
      speed: (json['speed'] is int)
          ? (json['speed'] as int).toDouble()
          : (json['speed'] ?? 0.0) as double,
      pace: json['pace'] != null
          ? (json['pace'] is int
              ? (json['pace'] as int).toDouble()
              : json['pace'] as double)
          : null,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      measuredHeight: json['measuredHeight'] != null
          ? (json['measuredHeight'] is int
              ? (json['measuredHeight'] as int).toDouble()
              : json['measuredHeight'] as double)
          : null,
      registeredHeight: json['registeredHeight'] != null
          ? (json['registeredHeight'] is int
              ? (json['registeredHeight'] as int).toDouble()
              : json['registeredHeight'] as double)
          : null,
      isHeightVerified: json['isHeightVerified'] as bool?,
      jumpHeight: json['jumpHeight'] != null
          ? (json['jumpHeight'] is int
              ? (json['jumpHeight'] as int).toDouble()
              : json['jumpHeight'] as double)
          : null,
      jumpType: json['jumpType'] as String?,
      repsCount: json['repsCount'] as int?,
      exerciseType: json['exerciseType'] as String?,
      flexibilityAngle: json['flexibilityAngle'] != null
          ? (json['flexibilityAngle'] is int
              ? (json['flexibilityAngle'] as int).toDouble()
              : json['flexibilityAngle'] as double)
          : null,
      flexibilityRating: json['flexibilityRating'] as String?,
      shuttleRunLaps: json['shuttleRunLaps'] as int?,
      directionChanges: json['directionChanges'] as int?,
      averageGpsAccuracy: json['averageGpsAccuracy'] != null
          ? (json['averageGpsAccuracy'] is int
              ? (json['averageGpsAccuracy'] as int).toDouble()
              : json['averageGpsAccuracy'] as double)
          : null,
    );
  }
}

