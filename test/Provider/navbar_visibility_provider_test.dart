import 'package:flutter_test/flutter_test.dart';
import 'package:next_level/Provider/navbar_visibility_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('keeps the selected main page aligned with visible navbar indices',
      () async {
    SharedPreferences.setMockInitialValues({
      'navbar_show_store': false,
      'navbar_show_inbox': true,
      'navbar_show_tasks': true,
      'navbar_show_notes': false,
      'navbar_show_projects': false,
      'navbar_main_page_index': 2,
    });

    final provider = NavbarVisibilityProvider();
    await provider.ready;

    expect(provider.getFirstVisiblePageIndex(), 2);
    expect(provider.mapPageIndexToVisibleIndex(2), 1);
    expect(provider.mapVisibleIndexToPageIndex(1), 2);
  });
}
