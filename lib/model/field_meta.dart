import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/model/streams.dart';

class FieldMeta {
  /// Private
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final NameStream _nameStream = NameStream();

  /// Public
  final String name;

  /// Getters
  TextEditingController get controller => _controller;
  bool get enabled => (FieldInput.validateInputField(name: name) == null);
  FocusNode get focusNode => _focusNode;
  double get opacity => (enabled) ? 1.0 : 0.2;
  Sink<String> get sink => _nameStream.sink;
  Stream<String> get stream => _nameStream.stream;

  FieldMeta({@required this.name}) : assert(name != null);

  void dispose() {
    _focusNode.dispose();
  }
}
