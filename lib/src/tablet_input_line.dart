import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/src/field_info_stream.dart';
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
  FieldInfo fieldInfo;
  List<FocusNode> focusNodes;
  List<TextEditingController> textEditingControllers;
  bool showTableColumn = false;

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
          visible: showTableColumn,
        ),
        columnComment,
      ],
    );
  }

  /// When the data type is changed it will affect the visibility of the 'table' column,
  /// (there is a table column only for 'array' and 'class' types)
  void _setVisibility(FieldInfo fieldInfo) {
    bool show = FieldInfo.isComplex(fieldInfo?.type);
    if (show == showTableColumn) return;
    setState(() {
      showTableColumn = show;
    });
  }

  /// Creates the widgets that make up the columns, uses a 'template' to reduce redundant code
  void columns() {
    fieldInfo = widget.fieldInfo;
    focusNodes = List();
    textEditingControllers = List();
    columnField = input(index: 0, flex: 5, value: fieldInfo?.field ?? '');
    columnJson = input(index: 1, flex: 5, value: fieldInfo?.json ?? '');
    columnDataType = dateTypeColumn(index: 2, flex: 2, value: fieldInfo?.type ?? '');
    columnTable = input(index: 3, flex: 5, value: fieldInfo?.table ?? '');
    columnComment = input(index: 4, flex: 10, fieldResult: widget.fieldInfoStream, value: fieldInfo?.comment ?? '');
  }

  /// Template to create an input column
  Widget input({
    /// The column number (zero based)
    @required int index,

    /// The flex factor to allow for adjustments base on screen width
    @required int flex,

    /// The last column must have handler for (tab/enter) from the keyboard. The design being that 'TAB'
    /// will create a new row for the same table and 'Enter/Return' will mean a new table is to be created.
    FieldInfoStream fieldResult,

    /// Initial value, if any, placed in the text input line via the columns TextEditingController
    @required String value,
  }) {
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
            if (chr == _TAB) {
              fieldInfo.setIndex(index, string: string);
              focusNodes[index].unfocus();

              /// If the 'Enter/Return' key was pressed but there is no handler, then just advance to the next field
              if (fieldResult == null) {
                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
              } else {
                /// If here, the last field received a 'Return/Enter' so the call back will report it was 'tabbed' out.
                fieldInfo.tabbedOut = true;
                fieldResult.add(fieldInfo);
              }
            }
          },
          onFieldSubmitted: (string) {
            fieldInfo.setIndex(index, string: string);
            focusNodes[index].unfocus();

            /// If the 'Enter/Return' key was pressed but there is no handler, then just advance to the next field
            if (fieldResult == null) {
              FocusScope.of(context).requestFocus(focusNodes[index + 1]);
            } else {
              /// If here, the last field received a 'Return/Enter' so the call back will report it was not 'tabbed' out.
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

  /// The dataTypeColumn is just a single letter for types (array, bool, class, datetime, int, real, string) so
  /// a special widget that handles only a single character is needed to ensure the type matches the allowed
  /// types and to show/hide the 'tableName column' that is associated with 'array' and 'class' types
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

            /// If there was a preloaded value, then a TAB will mean there is a character+TAB in the input field
            /// to handle this end chase, the string is checked and if not valid the cursor will force the
            /// update to stay in this column until a valid type is found
            if (string.length == 2 && chr == _TAB) {
              string = string.substring(0, 1);
              if (!FieldInfo.isDataTypes(string)) {
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
              if (FieldInfo.isComplex(type)) {
                Future.delayed(Duration(milliseconds: 250), () {
                  FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                });
              } else {
                if (FieldInfo.isDataTypes(type)) {
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
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      flex: flex,
    );
  }
}
