import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_tracers/trace.dart' as Log;

/// This class holds the information about a given input row, it can be the initial value provided
/// for TabletInputLine columns, or the data generated by TabletInputLine and sent back via a stream.
class FieldInput {
  /// Character/token allowed in the JSON-tag column to denote there is no JSon key for the given field
  static const ignoreJson = '-';
  static const _DataTypes = {'a', 'b', 'c', 'd', 'i', 'r', 's'};
  static bool isDataTypes(String type) => _DataTypes.contains(type);
  static bool isComplex(String type) => (type == 'a' || type == 'c');

  /// Use of regex expressions to make sure fields are valid to simplify input checking.
  static final _validCharacters = RegExp(r'^[a-zA-Z0-9_]+$');
  static final _validEnd = RegExp(r'^[a-zA-Z0-9]+$');
  static final _validStart = RegExp(r'^[a-zA-Z_]+$');

  /// Static constants are used to identify the input fields, this allows a reordering without a full refactor of most
  /// of the code in the TabletInputLine widget.
  static const indexField = 0;
  static const indexJson = 1;
  static const indexDataType = 2;
  static const indexTarget = 3;
  static const indexComment = 4;

  /// Properties of the items in the input form field, arrays are used to allow for re-ordering of input fields
  List<String> _items;
  List<String> _fieldsNames = List();
  List<FocusNode> _focusNodes = List();
  List<TextEditingController> _textEditControllers = List();

  /// Helpers to return string, focus, and controllers for fields by using indexes to allow for re-ordering of fields
  String fieldName({@required int forIndex}) => _fieldsNames[forIndex];
  FocusNode focusNode({@required int forIndex}) => _focusNodes[forIndex];
  TextEditingController textEditingController({@required int forIndex}) => _textEditControllers[forIndex];

  /// If the input was completed by the user hitting 'TAB', the UI should collect the fields, and present a new and
  /// empty form for the next field. If the user taps 'Enter' then a new table should prompted for an then present
  /// the input form with data going to the new table info.
  bool tabbedOut = false;

  /// Simple helpers to improve readability of code so that field names are clearing then an index.
  String get field => _items[indexField];
  String get json => _items[indexJson];
  String get type => _items[indexDataType];
  String get target => (isComplex(type)) ? _items[indexTarget] : '';
  String get comment => _items[indexComment];

  /// Perform syntax check on fields that cannot have blanks, must be only letters, numbers, underscore, and
  /// that do not end with underscore, the returned text is used in form validators
  static String _validField(String text) {
    if (text == null) return 'Cannot be null';
    if (text.trim().isEmpty) return 'Cannot be blank';
    var test = text.substring(0, 1);
    if (!_validStart.hasMatch(test)) return 'Invalid start character $test';
    test = text.substring(text.length - 1);
    if (!_validEnd.hasMatch(test)) return 'Invalid end character $test';
    if (!_validCharacters.hasMatch(text)) return 'Only letters and numbers';
    return null;
  }

  static String validateInputField({@required String name}) {
    return _validField(name);
  }

  ///* Constructor
  /// fieldNames is the text that appears above the TextInput fields. The number of names also defines the
  /// collection
  FieldInput({fieldNames = const ['Field', 'Json', 'a,b,c,d,i,r,s', 'Table', 'Comment']})
      : assert(fieldNames != null && fieldNames.length > 0) {
    _items = List.filled(fieldNames.length, '');
    _fieldsNames.addAll(fieldNames);
    for (int i = 0; i < fieldNames.length; i++) {
      _focusNodes.add(FocusNode(debugLabel: '?${fieldNames[i]}'));
      _textEditControllers.add(TextEditingController());
    }
  }

  void copyFromDB({@required BuildContext context, @required DBRecord record}) {
    setIndex(indexField, string: record.field);
    _textEditControllers[indexField].text = record.field;
    setIndex(indexJson, string: record.json);
    _textEditControllers[indexJson].text = record.json;
    setIndex(indexDataType, string: record.type);
    _textEditControllers[indexDataType].text = record.type;
    setIndex(indexTarget, string: record.target);
    _textEditControllers[indexTarget].text = record.target;
    setIndex(indexComment, string: record.comment);
    _textEditControllers[indexComment].text = record.comment;
    focusOnFirstField(context);
  }

  void dispose() {
    Log.w('field_input.dart dispose()');
    for (FocusNode focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (TextEditingController controller in _textEditControllers) {
      controller.dispose();
    }
  }

  void focusOnFirstField(BuildContext context) {
    assert(context != null, 'field_input.dart passed null context');
    FocusNode node = focusNode(forIndex: indexField);
    FocusScope.of(context).requestFocus(node);
  }

  /// To allow for re-ordering of fields, what is consider 'the next' field can vary so any requests for 'NextFocusNode'
  /// has to be calculated based on the current rules.... RIGHT NOW: the rule is to simple return the next FocusNode in the
  /// list of focus nodes.
  FocusNode nextFocusNode({@required int forIndex}) {
    assert(forIndex >= 0, 'field_input.dart nextField index ${forIndex.toString()}');
    assert(forIndex < _focusNodes.length, 'field_input.dart nextField index ${forIndex.toString()} > ${_focusNodes.length}');
    if (forIndex != indexDataType) return _focusNodes[forIndex + 1];
    return isComplex(type) ? _focusNodes[indexTarget] : _focusNodes[indexComment];
  }

  void reset({@required BuildContext context}) {
    assert(context != null, 'field_input.dart null context');
    _items = List.filled(_fieldsNames.length, '');
    for (TextEditingController controller in _textEditControllers) {
      controller.text = '';
    }
    Log.d('field_input focusOnFirstField(${context.toString()})');
    focusOnFirstField(context);
  }

  /// Validators for the the fields of an input line
  /// Field - begins with '_' or any upper/lower case letter, contains only letters/numbers/'_' and does not end with '_'
  /// Json - '-' to indicate there is not associated json key, else the same rules as Field
  /// DataType - only allow valid character that matches one of the data types (a,b,c,d,i,r,s)
  /// Target - if data type is array or class then Target is like Field, if not array or class must be empty
  /// Comment - No restrictions
  String validateAt({@required int index}) {
    final text = _items[index] ?? '';
    Log.t('FieldInput - validateAt($index) => $text');
    switch (index) {
      case indexField:
        return _validField(text);
      case indexJson:
        return (text == ignoreJson) ? null : _validField(text);
      case indexDataType:
        if (!isDataTypes(text)) return 'Invalid type';
        if (isComplex(text)) {
          return (validateAt(index: indexTarget) != null) ? 'Missing target table' : null;
        }
        return (_items[indexTarget].isNotEmpty) ? 'Target not allowed' : null;
      case indexTarget:
        if (isComplex(type)) return _validField(text);
        return text.isEmpty ? null : 'Target not allowed';
      case indexComment:
        return null;
      default:
        throw Exception('Invalid index = $index');
    }
  }

  void mock({bool complex = false}) {
    _items = List();
    _items.add('field');
    _items.add('json');
    _items.add(complex == true ? 'c' : 'i');
    _items.add('table');
    _items.add('comment');
  }

  /// The will load a string into an a fields data structure based on the index/key of that field at the same
  /// time as removing any trailing tabs that were used when 'tabbing-out' of a field to the next.
  String setIndex(int index, {@required String string}) {
    assert(index != null && index >= 0 && index < _items.length, '$index is invalid for size ${_items.length}');
    assert(string != null);
    while (string.isNotEmpty && string.endsWith('\t')) {
      string = string.substring(0, string.length - 1);
    }
    _items[index] = string;
    return _items[index];
  }

  /// Override toString to show more informative text than 'InstanceOf(field_input)' on the console
  String toString() => 'field:$field json:$json type:$type target:<$target> comment:"$comment"';
}
