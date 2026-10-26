import 'package:flutter_lms/utils/json_utils.dart';

class InstructorProfile {
  final String headline;
  final String qualification;
  final int experienceYears;
  final List<String> expertise;
  final String biography;

  const InstructorProfile({
    required this.headline,
    required this.qualification,
    required this.experienceYears,
    required this.expertise,
    required this.biography,
  });

  factory InstructorProfile.fromJson(Map<String, dynamic> json) {
    return InstructorProfile(
      headline: (json['headline'] ?? '').toString(),
      qualification: (json['qualification'] ?? '').toString(),
      experienceYears:
          int.tryParse(json['experienceYears']?.toString() ?? '') ?? 0,
      expertise: JsonUtils.stringList(json['expertise']),
      biography: (json['biography'] ?? '').toString(),
    );
  }
}