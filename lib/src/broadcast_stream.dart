import 'dart:convert';

import 'package:flutter/cupertino.dart';

/// This mixin is for classes that deal with json data and adds helper methods
/// to override 'toString()', and helper method 'dataString' that can turn
/// the class into a string suitable for http payloads or saving to a file.
/// It will also require the class to implement toJson() to create a map
/// of key/value pairs
mixin JsonData<T> {
  Map<String, dynamic> toJson();
  String toString() => dataString();
  String dataString({bool prettyPrint = false}) {
    prettyPrint ??= false;
    final encoder = prettyPrint ? JsonEncoder.withIndent('  ') : JsonEncoder();
    final map = toJson();
    return encoder.convert(map);
  }
}

//// This is just a playground

class BaseClass<S, T extends StatefulWidget> extends State<T> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}

class Z extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return null;
  }
}

class Mine extends BaseClass<String, Z> {}
