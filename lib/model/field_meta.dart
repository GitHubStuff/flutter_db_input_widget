//import 'package:flutter/material.dart';
//import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
//import 'package:flutter_db_input_widget/model/streams.dart';
//
//typedef NewNameFunction(String newName);
//
//class FieldMeta {
//  /// Private
//  final TextEditingController _controller = TextEditingController();
//  FocusNode _focusNode;
//  final NameStream _nameStream = NameStream();
//
//  /// Public
//  String _name;
//
//  /// Getters
//  TextEditingController get controller => _controller;
//  bool get enabled => (FieldInput.validateInputField(name: _name) == null);
//  FocusNode get focusNode => _focusNode;
//  String get name => _name;
//  double get opacity => (enabled) ? 1.0 : 0.2;
//  Sink<String> get sink => _nameStream.sink;
//  //Stream<String> get stream => _nameStream.stream;
//
//  FieldMeta({@required String fieldName, @required void newNameFunction(String newName), String debug = ''})
//      : assert(fieldName != null),
//        assert(newNameFunction != null) {
//    this._name = fieldName;
//    _focusNode = FocusNode(debugLabel: debug ?? '');
//    _nameStream.stream.listen((newName) {
//      _name = newName;
//      newNameFunction(newName);
//    });
//  }
//
//  void dispose() {
//    _focusNode.dispose();
//  }
//}
