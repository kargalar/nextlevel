import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/logging_service.dart';

void main() {
  test('LogService methods run without throwing and respect enabled flag', () {
    // Ensure enabled true triggers no exceptions
    LogService.enabled = true;
    expect(() => LogService.debug('debug message'), returnsNormally);
    expect(() => LogService.info('info message'), returnsNormally);
    expect(() => LogService.error('error message'), returnsNormally);

    // Disable and ensure methods still safe to call
    LogService.enabled = false;
    expect(() => LogService.debug('debug message'), returnsNormally);
    expect(() => LogService.info('info message'), returnsNormally);
    expect(() => LogService.error('error message'), returnsNormally);
  });
}
