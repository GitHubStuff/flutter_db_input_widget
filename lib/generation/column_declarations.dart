import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_strings/flutter_strings.dart' as Strings;

typedef RecordBuilder<T> = T Function(Map<String, dynamic> data);

//class ABCDEF extends SQL.SQLParse<ABCDEF> {
//  final String moose;
//  ABCDEF(this.moose);
//
//  factory ABCDEF.fromJson(Map<String, dynamic> json) {
//    String bob = 'Bob';
//    return ABCDEF(json['critter']);
//  }
//
//  @override
//  Map<String, dynamic> toJson() {
//    // TODO: implement toJson
//    String bob = 'Bob';
//    return null;
//  }
//}

class ColumnDeclarations {
  final DBRecord record;
  const ColumnDeclarations({this.record});

  /// Getters
  String get columnName => Strings.lowercase(record.field);
  String get columnSetter => Strings.capitalize(record.field);
  String get constructorParameter => '${_columnType()} $columnName,';
  String get constructorParameterAssignment => 'this.$columnName = $columnName;';
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

  String columnCreate() {
    if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) {
      return record.name;
    } else {
      return null;
    }
  }

  String columnDispose() {
    if (record.columnType == ColumnTypes.array || record.columnType == ColumnTypes.clazz) {
      return 'await delete$columnSetter();';
    } else {
      return null;
    }
  }

  String _columnType() {
    switch (record.columnType) {
      case ColumnTypes.array:
        return 'List<Map<String,dynamic>>';
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
    result.add('set $columnName(List<Map<String, dynamic>> newValue) => _$columnName = $targetName.buildArray(newValue);');
    return result;
  }

  List<String> _booleanColumn() {
    List<String> result = List();
    result.add('int _$columnName;${record.trailingComment}');
    result.add('bool get $columnName => (_$columnName == null) ? null : (_$columnName == 1);');
    result.add('set $columnName(dynamic newValue) => _$columnName = SQL.getBoolean(newValue) ? 1 : 0;');
    return result;
  }

  List<String> _classColumn() {
    List<String> result = List();
    result.add('${record.target} _$columnName;${record.trailingComment}');
    result.add('${record.target} get $columnName => _$columnName;');
    result.add('set $columnName(dynamic newValue) => _$columnName = $targetName.build(newValue);');
    return result;
  }

  List<String> _dateTimeColumn() {
    List<String> result = List();
    result.add('String _$columnName;${record.trailingComment}');
    result.add('DateTime get $columnName => SQL.getDateTime(_$columnName);');
    result.add('void set $columnName(dynamic newValue) => _$columnName = SQL.dateString(newValue);');
    return result;
  }

  List<String> _typeColumn() {
    final type = _columnType();
    List<String> result = List();
    result.add('$type _$columnName;${record.trailingComment}');
    result.add('$type get $columnName => _$columnName;');
    result.add('set $columnName($type newValue) => _$columnName = newValue;');
    return result;
  }
}
