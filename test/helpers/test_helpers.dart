import 'package:mockito/annotations.dart';
import 'package:next_level/Service/hive_service.dart';

import 'package:next_level/Repository/task_repository.dart';
import 'package:next_level/Repository/routine_repository.dart';
import 'package:next_level/Service/undo_service.dart';
import 'package:next_level/Service/home_widget_helper.dart';

import 'package:next_level/Repository/category_repository.dart';
import 'package:next_level/Provider/task_log_provider.dart';
import 'package:next_level/Repository/task_log_repository.dart';
import 'package:next_level/Provider/task_provider.dart';

@GenerateMocks([
  HiveService,
  TaskRepository,
  RoutineRepository,
  UndoService,
  HomeWidgetHelper,
  CategoryRepository,
  TaskLogProvider,
  TaskLogRepository,
  TaskProvider,
])
void main() {}
