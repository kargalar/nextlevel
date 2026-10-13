import 'package:next_level/Service/home_widget_service.dart';

class HomeWidgetHelper {
  Future<void> updateAllWidgets() async {
    await HomeWidgetService.updateAllWidgets();
  }
}
