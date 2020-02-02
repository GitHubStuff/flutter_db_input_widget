import 'package:flutter_sqlite_controller/flutter_sqlite_controller.dart' as DB;

class FirstTable {
  /// *** BODY ***

  /// Column keys
  static const String columnArrayField = 'arrayField';

  /// An array column
  static const String columnATextField = 'aTextField';

  /// Interesting string
  static const String columnBooleanField = 'booleanField';

  /// Boolean field
  static const String columnClassField = 'classField';

  /// A Clazz field
  static const String columnDateAndTimeField = 'dateAndTimeField';

  /// DateTime
  static const String columnIntegerField = 'integerField';

  /// integer with a lowercase
  static const String columnRealField = 'realField';

  /// In order

  /// Column declarations
  List<dynamic> _arrayField;

  /// An array column
  List<dynamic> get arrayField => _arrayField;
  dynamic arrayFieldAt(int index) => _arrayField[index];
  void setArrayField(List<dynamic> newValue) => _arrayField = newValue;
  void setArrayFieldAt(int index, dynamic newValue) => _arrayField[index] = newValue;

  String _aTextField;

  /// Interesting string
  String get aTextField => _aTextField;
  void setATextField(String newValue) => _aTextField = newValue;

  int _booleanField;

  /// Boolean field
  bool get booleanField => (_booleanField == 1);
  void setBooleanField(dynamic newValue) => _booleanField = DB.getBoolean(newValue) ? 1 : 0;

  dynamic _classField;

  /// A Clazz field
  dynamic get classField => _classField;
  void setClassField(dynamic newValue) => _classField = newValue;

  String _dateAndTimeField;

  /// DateTime
  DateTime get dateAndTimeField => DB.getDateTime(_dateAndTimeField);
  void setDateAndTimeField(dynamic newValue) => _dateAndTimeField = DB.dateString(newValue);

  int _integerField;

  /// integer with a lowercase
  int get integerField => _integerField;
  void setIntegerField(int newValue) => _integerField = newValue;

  double _realField;

  /// In order
  double get realField => _realField;
  void setRealField(double newValue) => _realField = newValue;

  FirstTable({
    List<dynamic> arrayField,
    String aTextField,
    dynamic booleanField,
    dynamic classField,
    dynamic dateAndTimeField,
    int integerField,
    double realField,
  }) {
    setArrayField(arrayField);
    setATextField(aTextField);
    setBooleanField(booleanField);
    setClassField(classField);
    setDateAndTimeField(dateAndTimeField);
    setIntegerField(integerField);
    setRealField(realField);
  }
}
