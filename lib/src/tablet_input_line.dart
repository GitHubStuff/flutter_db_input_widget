import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_tracers/trace.dart' as Log;

/// Displays an input line for fields name, json key, data type (array, bool, class, date, int, real, string),
/// a table name for 'array' and 'class' types, and comment field
///
/// This is the data needed to compose .dart files that handle sqlite code generation.

const _TAB = 9;

class TabletInputLine extends StatefulWidget {
  final FieldInfoStream fieldInfoStream;
  final FieldInfo fieldInfo;
  const TabletInputLine({Key key, @required this.fieldInfoStream, this.fieldInfo})
      : assert(fieldInfoStream != null),
        super(key: key);
  static const route = '/tabletInputLine';

  @override
  _TabletInputLine createState() => _TabletInputLine();
}

class _TabletInputLine extends State<TabletInputLine> with WidgetsBindingObserver, AfterLayoutMixin<TabletInputLine> {
  // a - array
  // b - bool
  // c - class
  // d - datetime
  // i - int
  // r - double
  // s - string
  Set get _dataTypes => {'a', 'b', 'c', 'd', 'i', 'r', 's'};
  FieldInfo fieldInfo;
  bool isDataTypes(String type) => _dataTypes.contains(type);
  bool isComplex(String type) => (type == 'a' || type == 'c');
  List<FocusNode> focusNodes = List();
  List<TextEditingController> textEditingControllers = List();
  bool showTableName = false;

  Widget columnField, columnJson, columnDataType, columnTable, columnComment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('tabletInputLine initState');

    /// Map the parameter data locally and create the widgets for the columns in the input row
    columns();
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('tabletInputLine didChangeDependencies');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('tabletInputLine didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    Log.t('tabletInputLine didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('tabletInputLine afterFirstLayout');
    _setVisibility(fieldInfo);
    Future.delayed(Duration(milliseconds: 250), () {
      FocusScope.of(context).requestFocus(focusNodes[0]);
      FocusScope.of(context).requestFocus(focusNodes[0]);
    });
  }

  @override
  Widget build(BuildContext context) {
    Log.t('tabletInputLine build');
    return body();
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('tabletInputLine didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('tabletInputLine deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('tabletInputLine dispose');
    WidgetsBinding.instance.removeObserver(this);
    for (FocusNode node in focusNodes) {
      node?.dispose();
    }
    for (TextEditingController controller in textEditingControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    return Row(
      children: [
        columnField,
        columnJson,
        columnDataType,
        Visibility(
          child: columnTable,
          visible: showTableName,
        ),
        columnComment,
      ],
    );
  }

  void _setVisibility(FieldInfo fieldInfo) {
    bool show = isComplex(fieldInfo?.type);
    if (show == showTableName) return;
    setState(() {
      showTableName = show;
    });
  }

  void columns() {
    fieldInfo = widget.fieldInfo;
    columnField = input(index: 0, flex: 5, value: fieldInfo?.field ?? '');
    columnJson = input(index: 1, flex: 5, value: fieldInfo?.json ?? '');
    columnDataType = dateTypeColumn(index: 2, flex: 2, value: fieldInfo?.type ?? '');
    columnTable = input(index: 3, flex: 5, value: fieldInfo?.table ?? '');
    columnComment = input(index: 4, flex: 10, fieldResult: widget.fieldInfoStream, value: fieldInfo?.comment ?? '');
  }

  Widget input({@required int index, @required int flex, FieldInfoStream fieldResult, @required String value}) {
    final focusNode = FocusNode(debugLabel: fieldInfo.fields[index]);
    final textController = TextEditingController();
    focusNodes.add(focusNode);
    textEditingControllers.add(textController);
    textController.text = value;
    return Flexible(
      child: Padding(
        child: TextFormField(
          controller: textController,
          decoration: InputDecoration(labelText: fieldInfo.fields[index]),
          focusNode: focusNodes[index],
          onChanged: (string) {
            final chr = string.runes.toList().last;
            Log.t('index:$index <$string> $chr');
            if (chr == _TAB) {
              fieldInfo.setIndex(index, string: string);
              focusNodes[index].unfocus();
              if (fieldResult == null) {
                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
              } else {
                fieldInfo.tabbedOut = true;
                fieldResult.add(fieldInfo);
              }
            }
          },
          onFieldSubmitted: (string) {
            fieldInfo.setIndex(index, string: string);
            focusNodes[index].unfocus();
            if (fieldResult == null) {
              FocusScope.of(context).requestFocus(focusNodes[index + 1]);
            } else {
              fieldInfo.tabbedOut = false;
              fieldResult.add(fieldInfo);
            }
          },
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      flex: flex,
    );
  }

  Widget dateTypeColumn({@required int index, @required int flex, @required String value}) {
    final focusNode = FocusNode(debugLabel: fieldInfo.fields[index]);
    focusNodes.add(focusNode);
    final controller = TextEditingController();
    textEditingControllers.add(controller);
    controller.text = value;
    return Flexible(
      child: Padding(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: fieldInfo.fields[index]),
          focusNode: focusNode,
          onChanged: (string) {
            final chr = string.runes.toList().last;
            if (string.length == 2 && chr == _TAB) {
              string = string.substring(0, 1);
              if (!isDataTypes(string)) {
                Future.delayed(Duration(milliseconds: 200), () {
                  controller.text = '';
                  FocusScope.of(context).requestFocus(focusNodes[index]);
                });
              }
            }
            if (string != '') {
              focusNodes[index].unfocus();
              final type = string.toLowerCase();
              fieldInfo.setIndex(index, string: string);
              _setVisibility(fieldInfo);
              if (isComplex(type)) {
                Future.delayed(Duration(milliseconds: 250), () {
                  FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                });
              } else {
                if (isDataTypes(type)) {
                  FocusScope.of(context).requestFocus(focusNodes[index + 2]);
                } else {
                  Future.delayed(Duration(milliseconds: 200), () {
                    controller.text = '';
                    FocusScope.of(context).requestFocus(focusNodes[index]);
                  });
                }
              }
            }
          },
          onFieldSubmitted: (string) {
            throw Exception('Should not reach here!');
          },
          validator: (value) {
            if (isDataTypes(value[0].toLowerCase())) return null;
            return _dataTypes.toString();
          },
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      flex: flex,
    );
  }
}
