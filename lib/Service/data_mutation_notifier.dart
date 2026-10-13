import 'dart:async';

class DataMutationNotifier {
  static final DataMutationNotifier _instance =
      DataMutationNotifier._internal();
  factory DataMutationNotifier() => _instance;
  DataMutationNotifier._internal();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get changes => _controller.stream;

  void markDirty(String entity) {
    _controller.add(entity);
  }
}
