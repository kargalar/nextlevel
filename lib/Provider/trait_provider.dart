import 'package:flutter/material.dart';
import 'package:next_level/Repository/trait_repository.dart';
import 'package:next_level/Model/trait_model.dart';

class TraitProvider with ChangeNotifier {
  // singelton
  TraitProvider._privateConstructor();
  static final TraitProvider _instance = TraitProvider._privateConstructor();
  factory TraitProvider() {
    return _instance;
  }

  List<TraitModel> traitList = [];
  final TraitRepository _repository = TraitRepository();

  void editTrait(TraitModel traitModel) async {
    traitList[traitList.indexWhere((element) => element.id == traitModel.id)] = traitModel;

    await _repository.updateTrait(traitModel);

    notifyListeners();
  }

  void addTrait(TraitModel traitModel) async {
    final int traitId = await _repository.addTrait(traitModel);

    traitModel.id = traitId;

    traitList.add(traitModel);

    notifyListeners();
  }

  void removeTrait(int id) async {
    await _repository.deleteTrait(id);

    traitList.removeWhere((element) => element.id == id);

    notifyListeners();
  }
}
