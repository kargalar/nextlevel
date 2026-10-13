import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Service/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AnalyticsService().clear();
  });

  test('counts local page views by page name', () async {
    AnalyticsService().trackPageView('HomePage');
    AnalyticsService().trackPageView('StorePage');
    AnalyticsService().trackPageView('HomePage');

    expect(
      await AnalyticsService().getPageViewCounts(),
      {'HomePage': 2, 'StorePage': 1},
    );
  });
}
