import 'package:flutter_lms/utils/json_utils.dart';

class StudentProfile {
  final String? dateOfBirth; // yyyy-MM-dd
  final String educationLevel;
  final List<String> learningGoals;

  const StudentProfile({
    this.dateOfBirth,
    required this.educationLevel,
    required this.learningGoals,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      dateOfBirth: JsonUtils.dateOnly(json['dateOfBirth']),
      educationLevel: (json['educationLevel'] ?? '').toString(),
      learningGoals: JsonUtils.stringList(json['learningGoals']),
    );
  }
}