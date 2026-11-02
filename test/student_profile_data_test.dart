import 'package:flutter_lms/models/student_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses student profile fields defensively', () {
    final profile = StudentProfile.fromJson({
      'dateOfBirth': '2004-03-19T00:00:00.000Z',
      'educationLevel': 'Undergraduate',
      'learningGoals': ['Flutter', null, 12, 'Backend'],
    });

    expect(profile.dateOfBirth, '2004-03-19');
    expect(profile.educationLevel, 'Undergraduate');
    expect(profile.learningGoals, ['Flutter', 'null', '12', 'Backend']);
  });
}
