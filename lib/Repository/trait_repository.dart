import 'package:next_level/Model/trait_model.dart';
import 'package:next_level/Service/hive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:next_level/Service/data_mutation_notifier.dart';

class TraitRepository {
  static final TraitRepository _instance = TraitRepository._internal();
  factory TraitRepository() => _instance;
  TraitRepository._internal();

  final HiveService _hiveService = HiveService();

  Future<List<TraitModel>> getTraits() async {
    return await _hiveService.getTraits();
  }

  Future<int> addTrait(TraitModel traitModel) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final int lastId = prefs.getInt("last_trait_id") ?? 0;

    // Set ID
    traitModel.id = lastId + 1;

    // Save locally first
    await _hiveService.addTrait(traitModel);

    // Update ID
    await prefs.setInt("last_trait_id", traitModel.id);
    DataMutationNotifier().markDirty('trait:add');

    return traitModel.id;
  }

  Future<void> updateTrait(TraitModel traitModel) async {
    await _hiveService.updateTrait(traitModel);
    DataMutationNotifier().markDirty('trait:update');
  }

  Future<void> deleteTrait(int id) async {
    await _hiveService.deleteTrait(id);
    DataMutationNotifier().markDirty('trait:delete');
  }
}
