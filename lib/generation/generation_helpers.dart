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
