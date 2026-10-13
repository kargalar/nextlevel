import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Core/task_progress_units.dart';

void main() {
  test('timer does not count current duration and its log twice', () {
    expect(
      TaskProgressUnits.timer(
        currentDuration: const Duration(minutes: 30),
        loggedDurations: const [Duration(minutes: 30)],
      ),
      const Duration(minutes: 30).inSeconds,
    );
  });

  test('timer falls back to logs when stored progress is empty', () {
    expect(
      TaskProgressUnits.timer(
        currentDuration: Duration.zero,
        loggedDurations: const [
          Duration(minutes: 10),
          Duration(minutes: 5),
        ],
      ),
      const Duration(minutes: 15).inSeconds,
    );
  });
}
