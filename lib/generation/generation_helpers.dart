import 'package:flutter/material.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

const BadInt = 100;
const BadString = 101;
const BadType = 102;
const BadWrite = 103;

/// For creating custom exceptions
class HelperException implements Exception {
  final message;
  final prefix;
  final code;
  HelperException([this.message, this.prefix, this.code]);
  String toString() {
    return '{$prefix: $message ($code)}';
  }
}

String makeGetter(String item, {bool includeSetter = false, @required int leadingSpaces, String type = 'bool', String value}) {
  assert(item != null);
  assert(includeSetter != null);
  assert(leadingSpaces >= 0);
  assert(type != null);
  value ??= '_' + item;
  final String space = Strings.pad(leadingSpaces);
  String result = space + '$type get $item => $value;';
  item = 'set' + Strings.capitalize(item);
  if (includeSetter) result = result + '\n' + space + 'void item($type newValue) => value = newValue';
  return result;
}

/// Takes a item from a map/dictionary and determines its bool value(or null)
/// to handled json like =>
///    { "isDone" : true },   {"isOver": false}
///    { "isDone" : "true" }  {"isOver": "false"}
///    { "isDone" : 1 }       {"isOver": 0 }
///
/// any value that is not an acceptable form of T/F will throw an exception.
bool ofJson(dynamic value) {
  if (value is bool || value == null) return value;
  if (value is int) {
    if (value != 0 && value != 1) throw InvalidBooleanException('$value is not 0 or 1', BadInt);
    return (value == 1);
  }
  if (value is String) {
    if (value.toLowerCase().startsWith('t') || value == '1') return true;
    if (value.toLowerCase().startsWith('f') || value == '0') return false;
    throw InvalidStringExpression('$value is not "true"/"false"/"1"/"0"', BadString);
  }
  throw InvalidTypeExpression('$value is not mappable must be bool, int, string', BadType);
}

/// Exceptions thrown by the helpers with information about the issue for calling methods to process
class FailedToWrite extends HelperException {
  FailedToWrite([message, int code]) : super(message, 'Failed to write data', code);
}

class InvalidBooleanException extends HelperException {
  InvalidBooleanException([message, int code]) : super(message, 'Integer value annot map to boolean', code);
}

class InvalidStringExpression extends HelperException {
  InvalidStringExpression([message, int code]) : super(message, 'String cannot map to boolean', code);
}

class InvalidTypeExpression extends HelperException {
  InvalidTypeExpression([message, int code]) : super(message, 'Cannot map to boolean', code);
}
