import 'package:flutter/material.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

enum HelperErrors { badInt, badString, badType, badWrite, createTableFilePath, failedToGenerate, userStop }

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

///**
List<String> makeGetter(String item, {bool includeSetter = true, @required int leadingSpaces, String type = 'bool', String value}) {
  assert(item != null);
  assert(includeSetter != null);
  assert(leadingSpaces >= 0);
  assert(type != null);
  value ??= '_' + item;
  List<String> results = List();
  String result = Strings.intent('$type get $item => $value;', leadingSpaces);
  results.add(result);
  result = Strings.intent('void set${Strings.capitalize(item)}($type newValue) => value = newValue;', leadingSpaces);
  if (includeSetter) results.add(result);
  return results;
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
    if (value != 0 && value != 1) throw InvalidBooleanException('$value is not 0 or 1', HelperErrors.badInt);
    return (value == 1);
  }
  if (value is String) {
    if (value.toLowerCase().startsWith('t') || value == '1') return true;
    if (value.toLowerCase().startsWith('f') || value == '0') return false;
    throw InvalidStringExpression('$value is not "true"/"false"/"1"/"0"', HelperErrors.badString);
  }
  throw InvalidTypeExpression('$value is not mappable must be bool, int, string', HelperErrors.badType);
}

/// Exceptions thrown by the helpers with information about the issue for calling methods to process
class CallbackStoppedGeneration extends HelperException {
  CallbackStoppedGeneration([message, HelperErrors code]) : super(message, 'Callback stopped code generation', code.index);
}

class CannotCreateTableFilePath extends HelperException {
  CannotCreateTableFilePath([message, HelperErrors code]) : super(message, 'Cannot creat a file path', code.index);
}

class FailedToGenerate extends HelperException {
  FailedToGenerate([message, HelperErrors code]) : super(message, 'Failed to generate files', code.index);
}

class FailedToWrite extends HelperException {
  FailedToWrite([message, HelperErrors code]) : super(message, 'Failed to write data', code.index);
}

class InvalidBooleanException extends HelperException {
  InvalidBooleanException([message, HelperErrors code]) : super(message, 'Integer value annot map to boolean', code.index);
}

class InvalidStringExpression extends HelperException {
  InvalidStringExpression([message, HelperErrors code]) : super(message, 'String cannot map to boolean', code.index);
}

class InvalidTypeExpression extends HelperException {
  InvalidTypeExpression([message, HelperErrors code]) : super(message, 'Cannot map to boolean', code.index);
}
