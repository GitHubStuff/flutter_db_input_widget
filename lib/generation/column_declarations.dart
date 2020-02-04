import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

typedef RecordBuilder<T> = T Function(Map<String, dynamic> data);

abstract class SQLParse<T> {
  Map<String, dynamic> toJson();

//  T fromData(dynamic data, RecordBuilder<T> builder) {
//    if (data is T) return data;
//    if (data is Map) return builder(data);
//    throw Exception('Unknown datatype ${T.toString()}');
//  }
//
//  List<T> fromArray(List<dynamic> array, RecordBuilder<T> builder) {
//    List<T> result = List();
//    for (dynamic item in array) {
//      if (item is Map) result.add(builder(item));
//      if (item is T) result.add(item);
//    }
//    return result;
//  }

  List<Map<String, dynamic>> jsonArray(List<T> data) {
    List<Map<String, dynamic>> result = List();
    for (T item in data) {
      final vector = (item as SQLParse);
      final data = vector.toJson();
      result.add(data);
    }
    return result;
  }
}

class ABC extends SQLParse<String> {
  final String moose;
  ABC(this.moose);

  factory ABC.fromJson(Map<String, dynamic> json) {
    String bob = 'Bob';
    return ABC(json['critter']);
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    String bob = 'Bob';
    return null;
  }
}

class ColumnDeclarations {
  final DBRecord record;
  const ColumnDeclarations({this.record});

  /// Getters
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
        return _classColumn();
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

  String get constructorParameter => '${_columnType()} $columnName,';
  String get constructorParameterAssignment => 'set$columnSetter($columnName);';

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
    result.add('void set$columnSetter(List<dynamic> newValue) => _$columnName = $targetName.BuildArray(newValue);');
    return result;
  }

  List<String> _booleanColumn() {
    List<String> result = List();
    result.add('int _$columnName;${record.trailingComment}');
    result.add('bool get $columnName => (_$columnName == 1);');
    result.add('void set$columnSetter(dynamic newValue) => _$columnName = SQL.getBoolean(newValue) ? 1 : 0;');
    return result;
  }

  List<String> _classColumn() {
    List<String> result = List();
    result.add('${record.target} _$columnName;${record.trailingComment}');
    result.add('${record.target} get $columnName => _$columnName;');
    result.add('void set${Strings.capitalize(record.target)}(dynamic newValue) => _$columnName = $targetName.Build(newValue);');
    return result;
  }

  List<String> _dateTimeColumn() {
    List<String> result = List();
    result.add('String _$columnName;${record.trailingComment}');
    result.add('DateTime get $columnName => SQL.getDateTime(_$columnName);');
    result.add('void set$columnSetter(dynamic newValue) => _$columnName = SQL.dateString(newValue);');
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
