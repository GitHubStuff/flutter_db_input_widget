import 'package:flutter_db_input_widget/generation/fixed_headers.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

typedef RecordBuilder<T> = T Function(Map<String, dynamic> data);

abstract class SQLParse<T> {
  T fromJson(Map<String, dynamic> data);
  T fromData(dynamic data, RecordBuilder<T> builder) {
    if (data is Map) return builder(data);
    if (data is T) return data;
    throw Exception('Unknown datatype ${T.toString()}');
  }
}

class ABC extends SQLParse<String> {
  final String moose;
  ABC(this.moose);

  factory ABC.fromJson(Map<String, dynamic> json) {}
  @override
  String fromJson(Map<String, dynamic> data) {
    // TODO: implement fromJson
    return null;
  }
}

class ColumnDeclarations {
  final DBRecord record;
  const ColumnDeclarations({this.record});

  String get columnName => Strings.lowercase(record.field);
  String get columnSetter => Strings.capitalize(record.field);
  String get targetName => Strings.capitalize(record.target);

  List<String> columnDeclaration() {
    switch (record.columnType) {
      case ColumnTypes.array:
        return _arrayColumns();
      case ColumnTypes.boolean:
        return _booleanColumn();
      case ColumnTypes.clazz:
        return _typeColumn();
      case ColumnTypes.date:
        return _dateTimeColumn();
      case ColumnTypes.double:
        return _typeColumn();
      case ColumnTypes.integer:
        return _typeColumn();
      case ColumnTypes.string:
        return _typeColumn();
      default:
        throw Exception('column_declarations: Cannot parse ${record.columnType.toString()}');
    }
  }

  String get constructorParameter => Strings.indent('${_columnType()} $columnName,', parameterIntent);
  String get constructorParameterAssignment => Strings.indent('set$columnSetter($columnName);', parameterIntent);

  String _columnType() {
    switch (record.columnType) {
      case ColumnTypes.array:
        return 'List<dynamic>';
      case ColumnTypes.boolean:
        return 'dynamic';
      case ColumnTypes.clazz:
        return 'dynamic';
      case ColumnTypes.date:
        return 'dynamic';
      case ColumnTypes.double:
        return 'double';
      case ColumnTypes.integer:
        return 'int';
      case ColumnTypes.string:
        return 'String';
      default:
        throw Exception('column_declarations: Cannot parse ${record.columnType.toString()}');
    }
  }

  List<String> _arrayColumns() {
    List<String> result = List();
    result.add('List<$targetName> _$columnName;${record.trailingComment}');
    result.add('List<$targetName> get $columnName => _$columnName;');
    result.add('$targetName get ${columnName}At(int index) => _$columnName[index];');
    result.add('void set$columnSetter(List<dynamic> newValue) => _$columnName = newValue;');
    result.add('void set${columnSetter}At(int index, dynamic newValue) => _$columnName(index) = newValue;');
    return result;
  }

  List<String> _booleanColumn() {
    List<String> result = List();
    result.add('int _$columnName;${record.trailingComment}');
    result.add('bool get $columnName => (_$columnName == 1);');
    result.add('void set$columnSetter(dynamic newValue) => _$columnName = DB.getBoolean(newValue)');
    return result;
  }

  List<String> _dateTimeColumn() {
    List<String> result = List();
    result.add('String _$columnName;${record.trailingComment}');
    result.add('DateTime get $columnName => DB.getDateTime(_$columnName);');
    result.add('void set$columnSetter(dynamic newValue) => _$columnName = DB.dateString(newValue)');
    return result;
  }

  List<String> _typeColumn() {
    final type = _columnType();
    List<String> result = List();
    result.add('$type _$columnName;${record.trailingComment}');
    result.add('$type get $columnName => _$columnName;');
    result.add('void set$columnSetter($type newValue) => _$columnName = newValue;');
    return result;
  }
}
