import 'dart:async';

import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';

abstract class Streaming<T> {
  final StreamController<T> _streamController = StreamController<T>();
  Stream get stream => _streamController.stream;
  void add(T value) {
    _streamController.add(value);
  }

  void dispose() {
    _streamController.close();
  }
}

class FieldInfoStream extends Streaming<FieldInfo> {}
