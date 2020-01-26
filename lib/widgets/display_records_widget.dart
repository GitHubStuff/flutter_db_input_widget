import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_tracers/trace.dart' as Log;

import 'record_widget.dart';

class DisplayRecordsWidget extends StatefulWidget {
  /// To push the selected record for display in the input-editor fields
  final Sink<DBRecord> sink;
  final List<DBRecord> tables;
  const DisplayRecordsWidget({Key key, @required this.sink, @required this.tables})
      : assert(sink != null),
        super(key: key);

  @override
  _DisplayWidget createState() => _DisplayWidget();
}

class _DisplayWidget extends State<DisplayRecordsWidget> with WidgetsBindingObserver, AfterLayoutMixin<DisplayRecordsWidget> {
  final scrollController = ScrollController();
  // ignore: non_constant_identifier_names
  Size get ScreenSize => MediaQuery.of(context).size;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('displayRecordsWidget initState');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('displayRecordsWidget afterFirstLayout');
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('displayRecordsWidget didChangeDependencies');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('displayRecordsWidget didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    Log.t('displayRecordsWidget didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    return body();
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('displayRecordsWidget didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('displayRecordsWidget deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('displayRecordsWidget dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    final h = ScreenSize.height;
    final ht = h * 0.2;
    return Container(
      height: ht,
      child: ListView.separated(
        controller: scrollController,
        itemBuilder: (context, index) {
          return widgetAt(index);
        },
        itemCount: widget.tables.length,
        separatorBuilder: (a, b) => Container(height: 4.0),
        shrinkWrap: true,
      ),
    );
  }

  Widget widgetAt(int index) {
    if (index >= widget.tables.length) return null;
    return RecordWidget(
      dbRecord: widget.tables[index],
      index: index,
      fieldSelect: (idx, dbRecord) {
        Log.t('index $idx data: ${dbRecord.toString()}');
        widget.sink.add(dbRecord);
      },
    );
  }
}
