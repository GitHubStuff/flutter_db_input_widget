import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_db_input_widget/src/broadcast_stream.dart';
import 'package:flutter_tracers/trace.dart' as Log;

import '../src/field_input.dart';

/// Displays an input line for fields name, json key, data type (array, bool, class, date, int, real, string),
/// a table name for 'array' and 'class' types, and comment field
///
/// This is the data needed to compose .dart files that handle sqlite code generation.

const _TAB = 9;

class InputCompleteStream extends BroadcastStream<FieldInput> {
  @override
  void dispose() {
    close();
  }
}

class InputSelectedStream extends BroadcastStream<DBRecord> {
  @override
  void dispose() {
    close();
  }
}

class TabletInputLine extends StatefulWidget {
  final FieldInput fieldInput;
  final Sink<FieldInput> sink;
  const TabletInputLine({Key key, this.fieldInput, @required this.sink})
      : assert(fieldInput != null),
        assert(sink != null),
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
  FieldInput fieldInput;
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
    columns(widget.fieldInput);
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

    /// After the initial layout completes, set the visibility of the target-table field
    /// based on the data type that was passed to the widget
    setVisibility(fieldInput);
    setFocus();
  }

  @override
  Widget build(BuildContext context) {
    Log.t('tabletInputLine build');
    return body();
  }

  /// Stumbled on this one.... after the fields have been field out and to clear
  /// and reset, 'didUpdateWidget' is called when a new instance of the this widget
  /// is created. The render engine doesn't rebuild the widget on create but calls
  /// this method when an empty FieldInput IS passed when a new widget it created.
  /// *Very Confusing*
  /// So after the input finishes on the main widget tree, a new instance of TabletInputLine
  /// is created with an empty instance of FieldInput which in turn calls this method,
  /// where an empty instance of FieldInput is created and focus is set to the first
  /// input field.
  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('tabletInputLine didUpdateWidget');
    Log.t('widget ${widget.fieldInput.toString()}');
    columns(widget.fieldInput);
    setFocus();
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

    /// Required house keeping on disposing of FocusNodes and TextEditingControllers
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

  /// Weird hack to get the keyboard to focus/appear on the first field of the form.
  void setFocus() {
    Future.delayed(Duration(milliseconds: 250), () {
      FocusScope.of(context).requestFocus(focusNodes[0]);
      FocusScope.of(context).requestFocus(focusNodes[0]);
    });
  }

  /// When the data type is changed it will affect the visibility of the 'table' column,
  /// (there is a table column only for 'array' and 'class' types)
  void setVisibility(FieldInput fieldInfo) {
    bool show = FieldInput.isComplex(fieldInfo?.type);
    if (show == showTableColumn) return;
    setState(() {
      showTableColumn = show;
    });
  }

  /// Creates the widgets that make up the columns, uses a 'template' to reduce redundant code
  void columns(FieldInput source) {
    fieldInput = source;
    focusNodes = List();
    textEditingControllers = List();
    columnField = input(index: 0, flex: 5, value: fieldInput?.field ?? '');
    columnJson = input(index: 1, flex: 5, value: fieldInput?.json ?? '');
    columnDataType = dateTypeColumn(index: 2, flex: 2, value: fieldInput?.type ?? '');
    columnTable = input(index: 3, flex: 5, value: fieldInput?.target ?? '');
    columnComment = input(index: 4, flex: 10, fieldSink: widget.sink, value: fieldInput?.comment ?? '');
  }

  /// Template to create an input column
  /// NOTE: The last column must have handler for (tab/enter) from the keyboard. The design being that 'TAB'
  /// will create a new row for the same table and 'Enter/Return' will mean a new table is to be created.
  /// NOTE: All fields but the last one CANNOT be empty, the cursor will not advance on 'TAB' or 'ENTER'
  Widget input({
    @required int index,
    @required int flex,
    Sink<FieldInput> fieldSink,
    @required String value,
  }) {
    final focusNode = FocusNode(debugLabel: fieldInput.fields[index]);
    final textController = TextEditingController();
    focusNodes.add(focusNode);
    textEditingControllers.add(textController);
    textController.text = value;
    return Flexible(
      child: Padding(
        child: TextFormField(
          autocorrect: fieldSink != null,
          controller: textController,
          decoration: InputDecoration(labelText: fieldInput.fields[index]),
          enableSuggestions: fieldSink != null,
          focusNode: focusNodes[index],
          onChanged: (string) {
            handlerAdvance(text: string, isTabbed: true, index: index, sink: fieldSink);
          },
          onFieldSubmitted: (string) {
            handlerAdvance(text: string, isTabbed: false, index: index, sink: fieldSink);
          },
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      flex: flex,
    );
  }

  void handlerAdvance({@required String text, @required bool isTabbed, @required int index, @required Sink<FieldInput> sink}) {
    if ((text.isEmpty || text == '\t') && sink == null) {
      Future.delayed(Duration(milliseconds: 200), () {
        textEditingControllers[index].text = '';
        FocusScope.of(context).requestFocus(focusNodes[index]);
      });
      return;
    }
    final chr = text.runes.toList().last;
    if (chr == _TAB || !isTabbed) {
      final putString = fieldInput.setIndex(index, string: text);
      textEditingControllers[index].text = putString;

      /// If the 'Enter/Return' key was pressed but there is no handler, then just advance to the next field
      if (sink == null) {
        FocusScope.of(context).requestFocus(focusNodes[index + 1]);
      } else {
        /// If here, the last field received a 'Return/Enter' so the call back will report it was 'tabbed' out.
        fieldInput.tabbedOut = isTabbed;
        sink.add(fieldInput);
      }
    }
  }

  /// The dataTypeColumn is just a single letter for types (array, bool, class, datetime, int, real, string) so
  /// a special widget that handles only a single character is needed to ensure the type matches the allowed
  /// types and to show/hide the 'tableName column' that is associated with 'array' and 'class' types
  Widget dateTypeColumn({@required int index, @required int flex, @required String value}) {
    final focusNode = FocusNode(debugLabel: fieldInput.fields[index]);
    focusNodes.add(focusNode);
    final controller = TextEditingController();
    textEditingControllers.add(controller);
    controller.text = value;
    return Flexible(
      child: Padding(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: fieldInput.fields[index]),
          focusNode: focusNode,
          onChanged: (string) {
            while (string.length > 1) {
              string = (string.substring(0, string.length - 1)).toLowerCase();
            }
            if (!FieldInput.isDataTypes(string)) {
              Future.delayed(Duration(milliseconds: 200), () {
                textEditingControllers[index].text = '';
              });
            } else {
              textEditingControllers[index].text = fieldInput.setIndex(index, string: string);
              setVisibility(fieldInput);
              final nextFocus = FieldInput.isComplex(string) ? focusNodes[index + 1] : focusNodes[index + 2];
              Future.delayed(Duration(milliseconds: 200), () {
                FocusScope.of(context).requestFocus(nextFocus);
              });
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
