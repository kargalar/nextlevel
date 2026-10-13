import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/hive_service.dart';

void main() {
  test('normal launch generates every day after the last login', () {
    final dates = HiveService.routineGenerationDates(
      lastLoginDate: DateTime(2026, 7, 10, 23),
      today: DateTime(2026, 7, 13, 9),
    );

    expect(
      dates,
      [
        DateTime(2026, 7, 11),
        DateTime(2026, 7, 12),
        DateTime(2026, 7, 13),
      ],
    );
  });

  test('restore start date skips the non-lived backup gap', () {
    final dates = HiveService.routineGenerationDates(
      lastLoginDate: DateTime(2026, 6, 1),
      today: DateTime(2026, 7, 16, 14),
      generationStartDate: DateTime(2026, 7, 16, 14),
    );

    expect(dates, [DateTime(2026, 7, 16)]);
  });
}
