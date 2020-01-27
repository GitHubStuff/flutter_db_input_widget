import 'dart:io';
import 'dart:math';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_tracers/trace.dart' as Log;

/// Widget to display list of tables and fields in a list view, with a icon button to select a field to
/// edit.

typedef void FieldSelect(int index, DBRecord record);

class RecordWidget extends StatefulWidget {
  final DBRecord dbRecord;
  final int index;
  final FieldSelect fieldSelect;
  const RecordWidget({Key key, @required this.dbRecord, @required this.index, @required this.fieldSelect})
      : assert(dbRecord != null),
        assert(index != null && index >= 0),
        assert(fieldSelect != null),
        super(key: key);

  @override
  _RecordWidget createState() => _RecordWidget();
}

class _RecordWidget extends State<RecordWidget> with WidgetsBindingObserver, AfterLayoutMixin<RecordWidget> {
  final String padded = '                    ';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('recordWidget initState');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('recordWidget afterFirstLayout');
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('recordWidget didChangeDependencies');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('recordWidget didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    Log.t('recordWidget didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('recordWidget didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('recordWidget deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('recordWidget dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final table = (widget.dbRecord.name + padded).substring(0, 15);
    final column = (widget.dbRecord.field + padded).substring(0, 15);
    final json = (widget.dbRecord.json + padded).substring(0, 15);
    String dataType = '';
    switch (widget.dbRecord.type) {
      case 'a':
        dataType = '(a)rray';
        break;
      case 'b':
        dataType = '(b)ool';
        break;
      case 'c':
        dataType = '(c)lass';
        break;
      case 'd':
        dataType = '(d)ate';
        break;
      case 'i':
        dataType = '(i)nt';
        break;
      case 'r':
        dataType = '(r)eal/double';
        break;
      case 's':
        dataType = '(s)tring';
        break;
    }
    final type = (dataType + padded).substring(0, 14);
    final target = (widget.dbRecord.target + padded).substring(0, 14);
    final comment = widget.dbRecord.comment.substring(0, min(14, widget.dbRecord.comment.length));
    final TextStyle textStyle = Theme.of(context).textTheme.title.copyWith(fontFamily: Platform.isIOS ? "Courier" : "monospace");
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            icon: Icon(
              Icons.adjust,
              size: 44.0,
              semanticLabel: 'Adjust',
            ),
            onPressed: () {
              widget.fieldSelect(widget.index, widget.dbRecord);
            },
          ),
        ),
        Text(
          '$table $column $json $type $target //$comment',
          style: textStyle,
        ),
      ],
    );
  }
}
