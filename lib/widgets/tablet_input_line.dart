import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tracers/trace.dart' as Log;

import '../src/field_input.dart';

/// Displays an input line for fields name, json key, data type (array, bool, class, date, int, real, string),
/// a table name for 'array' and 'class' types, and comment field
///
/// This is the data needed to compose .dart files that handle sqlite code generation.

final tabletInputLineKey = GlobalKey<_TabletInputLine>();

/// Widget that will display input fields to collect the columnName, json tag, data type, target table(if any), and comment
/// text the user inputs.
class TabletInputLine extends StatefulWidget {
  final FieldInput fieldInput;
  final Sink<FieldInput> sink;
  const TabletInputLine({Key key, this.fieldInput, @required this.sink})
      : assert(fieldInput != null),
        assert(sink != null),
        super(key: key);

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
  final formKey = GlobalKey<FormState>();
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
  }

  @override
  Widget build(BuildContext context) {
    Log.t('tabletInputLine build');
    return body();
  }

  /// Stumbled on this one.... after the fields have been tabbed out and to clear
  /// and reset, 'didUpdateWidget' is called when a new instance of the this widget
  /// is created. The render engine doesn't appear to rebuild the widget on create but calls
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
    Log.t('tabletInputLine dispose()');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    return Form(
      child: Row(
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
      ),
      key: formKey,
    );
  }

  /// Creates the widgets that make up the columns, uses a 'template' to reduce redundant code
  void columns(FieldInput source) {
    fieldInput = source;
    columnField = fieldInputWidget(index: FieldInput.indexField, flex: 5, value: fieldInput?.field ?? '');
    columnJson = fieldInputWidget(index: FieldInput.indexJson, flex: 5, value: fieldInput?.json ?? '');
    columnDataType = dataTypeColumn(index: FieldInput.indexDataType, flex: 2, value: fieldInput?.type ?? '');
    columnTable = fieldInputWidget(index: FieldInput.indexTarget, flex: 5, value: fieldInput?.target ?? '');
    columnComment =
        fieldInputWidget(index: FieldInput.indexComment, flex: 10, fieldSink: widget.sink, value: fieldInput?.comment ?? '');
  }

  /// The dataTypeColumn is just a single letter for types (array, bool, class, datetime, int, real, string) so
  /// a special widget that handles only a single character is needed to ensure the type matches the allowed
  /// types and to show/hide the 'Target' field that is associated with 'array' and 'class' types
  Widget dataTypeColumn({@required int index, @required int flex, @required String value}) {
    final focusNode = fieldInput.focusNode(forIndex: index);
    final controller = fieldInput.textEditingController(forIndex: index);
    controller.text = value;
    return Flexible(
      child: Padding(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: fieldInput.fieldName(forIndex: index)),
          focusNode: focusNode,
          onChanged: (string) {
            while (string.length > 1) {
              string = (string.substring(0, string.length - 1)).toLowerCase();
            }
            if (!FieldInput.isDataTypes(string)) {
              Future.delayed(Duration(milliseconds: 200), () {
                controller.text = '';
              });
            } else {
              controller.text = fieldInput.setIndex(index, string: string);
              setVisibility(fieldInput);
              final nextIndex = FieldInput.isComplex(string) ? FieldInput.indexTarget : FieldInput.indexComment;
              final nextFocus = fieldInput.focusNode(forIndex: nextIndex);
              Future.delayed(Duration(milliseconds: 200), () {
                FocusScope.of(context).requestFocus(nextFocus);
              });
            }
          },
          onFieldSubmitted: (string) {
            throw Exception('Should not reach here!');
          },
          textInputAction: TextInputAction.next,
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      flex: flex,
    );
  }

  /// Template to create an input column
  /// NOTE: The last column must have handler for (tab/enter) from the keyboard. The design being that 'TAB'
  /// will create a new row for the same table and 'Enter/Return' will mean a new table is to be created.
  /// NOTE: All fields but the last one CANNOT be empty, the cursor will not advance on 'TAB' or 'ENTER'
  Widget fieldInputWidget({
    @required int index,
    @required int flex,
    Sink<FieldInput> fieldSink,
    @required String value,
  }) {
    final focusNode = fieldInput.focusNode(forIndex: index);
    final textController = fieldInput.textEditingController(forIndex: index);
    textController.text = value;
    if (!mounted) return null;
    return Flexible(
      child: Padding(
        child: TextFormField(
          autocorrect: fieldSink != null,
          controller: textController,
          decoration: InputDecoration(labelText: fieldInput.fieldName(forIndex: index)),
          enableSuggestions: fieldSink != null,
          focusNode: focusNode,
          onChanged: (string) {
            handlerAdvance(text: string, isTabbed: true, index: index, sink: fieldSink);
          },
          onFieldSubmitted: (string) {
            handlerAdvance(text: string, isTabbed: false, index: index, sink: fieldSink);
          },
          textInputAction: (fieldSink == null) ? TextInputAction.next : TextInputAction.done,
          validator: (text) {
            return fieldInput.validateAt(index: index);
          },
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
      ),
      flex: flex,
    );
  }

  /// When the 'tab' or 'enter' key is pressed, the current field is checked to see if the input is valid before advancing
  /// to the next field. As several rules apply (eg: only the 'last' field has a Stream.sink to return data, all other fields
  /// must have at least one character before advancing, if there is a Stream.sink, then all fields must be validated before
  /// anything is returned via the Stream.sink)...
  void handlerAdvance({@required String text, @required bool isTabbed, @required int index, @required Sink<FieldInput> sink}) {
    /// If the field is empty but not the 'last' field, then a blank/tabbed field is not permitted and focus stays on
    /// the current field
    if ((text.isEmpty || text == '\t') && sink == null) {
      Future.delayed(Duration(milliseconds: 200), () {
        Log.d('tabline_input_line handlerAdvance() set focus');
        fieldInput.textEditingController(forIndex: index).text = '';
        FocusScope.of(context).requestFocus(fieldInput.focusNode(forIndex: index));
      });
      return;
    }

    /// Get the last character to check for 'TAB', or if 'Enter' was pressed (aka !isTabbed)
    if (text.endsWith('\t') || !isTabbed) {
      /// Set the text in the backing store (will be used later for whole line validate)
      final putString = fieldInput.setIndex(index, string: text);
      fieldInput.textEditingController(forIndex: index).text = putString;

      /// If the 'Enter/Return' key was pressed but there is no handler, then just advance to the next field
      if (sink == null) {
        FocusScope.of(context).requestFocus(fieldInput.nextFocusNode(forIndex: index));
      } else {
        /// If here, the last field received a 'Return/Enter' so the call back will report it was 'tabbed' out.
        if (formKey.currentState.validate()) {
          fieldInput.tabbedOut = isTabbed;
          sink.add(fieldInput);
        }
      }
    }
  }

  /// Weird hack to get the keyboard to focus/appear on the first field of the form.
  void setFocus() {
    Log.d('tablet_input_line setFocus()');
    Future.delayed(Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(fieldInput.focusNode(forIndex: FieldInput.indexField));
      FocusScope.of(context).requestFocus(fieldInput.focusNode(forIndex: FieldInput.indexField));
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
}
