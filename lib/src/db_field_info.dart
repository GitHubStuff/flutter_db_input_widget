import 'dart:async';

import 'package:flutter/material.dart';

class FieldInfo {
  List<String> _items;
  final List<String> fields;
  bool tabbedOut = false;
  String get field => _items[0];
  String get json => _items[1];
  String get type => _items[2];
  String get table => _items[3];
  String get comment => _items[4];

  FieldInfo({this.fields = const ['Field', 'Json', 'a,b,c,d,i,r,s', 'Table', 'Comment']})
      : assert(fields != null && fields.length > 0) {
    _items = List.filled(fields.length, '');
  }
  void mock({bool complex = false}) {
    _items = List();
    _items.add('field');
    _items.add('json');
    _items.add(complex == true ? 'c' : 'i');
    _items.add('table');
    _items.add('comment');
  }

  setIndex(int index, {@required String string}) {
    assert(index != null && index >= 0 && index < _items.length, '$index is invalid for size ${_items.length}');
    assert(string != null);
    final chr = string.runes.toList().last;
    if (chr == 9) string = string.substring(0, string.length - 1);
    _items[index] = string;
  }
}

class FieldInfoStream extends Streaming<FieldInfo> {}

abstract class Streaming<T> {
  final StreamController<T> _streamController = StreamController<T>();
  //StreamController<T> get controller => _streamController;
  Stream get stream => _streamController.stream;
  void add(T value) {
    _streamController.add(value);
  }

  void dispose() {
    _streamController.close();
  }
}
