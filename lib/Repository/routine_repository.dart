import 'package:flutter/foundation.dart';
import 'package:next_level/Model/routine_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class RoutineRepository {
  static final RoutineRepository _instance = RoutineRepository._internal();
  factory RoutineRepository() => _instance;
  RoutineRepository._internal();

  HiveService _hiveService = HiveService();

  @visibleForTesting
  void setHiveService(HiveService service) {
    _hiveService = service;
  }

  Future<List<RoutineModel>> getRoutines() async {
    return await _hiveService.getRoutines();
  }

  Future<int> addRoutine(RoutineModel routineModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int lastId = prefs.getInt("last_routine_id") ?? 0;

    // Get all existing routines to ensure we don't have ID conflicts
    final existingRoutines = await _hiveService.getRoutines();

    // Find the highest ID among existing routines
    int highestId = lastId;
    for (final routine in existingRoutines) {
      if (routine.id > highestId) {
        highestId = routine.id;
      }
    }

    // Set the new routine ID to be one higher than the highest existing ID
    routineModel.id = highestId + 1;

    // Save the routine
    await _hiveService.addRoutine(routineModel);

    // Update the last routine ID in SharedPreferences
    await prefs.setInt("last_routine_id", routineModel.id);
    DataMutationNotifier().markDirty('routine:add');

    return routineModel.id;
  }

  Future<void> updateRoutine(RoutineModel routineModel) async {
    await _hiveService.updateRoutine(routineModel);
    DataMutationNotifier().markDirty('routine:update');
  }

  Future<void> deleteRoutine(int id) async {
    await _hiveService.deleteRoutine(id);
    DataMutationNotifier().markDirty('routine:delete');
  }
}
