import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_theme_package/flutter_theme_package.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:notifier/notifier_provider.dart';

void main() {
  runApp(NotifierProvider(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModeTheme(
      data: (brightness) => (brightness == Brightness.light) ? ModeThemeData.bright() : ModeThemeData.dark(),
      defaultBrightness: Brightness.light,
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          home: Example(),
          initialRoute: '/',
          routes: {
            Example.route: (context) => MyApp(),
          },
          theme: theme,
          title: 'Example Demo',
        );
      },
    );
  }
}

class Example extends StatefulWidget {
  const Example({Key key}) : super(key: key);
  static const route = '/example';

  @override
  _Example createState() => _Example();
}

class _Example extends State<Example> with WidgetsBindingObserver, AfterLayoutMixin<Example> {
  // ignore: non_constant_identifier_names
  Size get ScreenSize => MediaQuery.of(context).size;

  bool hideSpinner = true;
  String caption = 'Start';
  int counter = 0;
  double listHeight = 300.0;
  DBProjectBloc projectBloc;
  String tableName = 'VeryFirst';
  KeyboardVisibilityNotification keyboardVisibilityNotification = KeyboardVisibilityNotification();
  List<DBRecord> listOfTables = List();

  FieldInput fieldInput = FieldInput();
  TabletInputLine tabletInputLine;
  InputCompleteStream inputCompleteStream = InputCompleteStream();
  InputSelectedStream inputSelectedStream = InputSelectedStream();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('example initState');
    tabletInputLine = TabletInputLine(fieldInput: fieldInput, sink: inputCompleteStream.sink);
    keyboardVisibilityNotification.addNewListener(onShow: () {
      setState(() {
        listHeight = ScreenSize.height * 0.25;
        Log.f('main.dart show listHeight $listHeight');
      });
    }, onHide: () {
      Log.v('main.dart onHide');
      expand();
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('example didChangeDependencies');
    Log.v('example didChangeDependencies => $listHeight');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('example didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    ModeTheme.of(context).setBrightness(brightness);
    Log.t('example didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('example afterFirstLayout');
    expand();
    make();
    listener();
  }

  @override
  Widget build(BuildContext context) {
    Log.t('example build');
    return HudScaffold.progressText(
      context,
      hide: hideSpinner,
      indicatorColors: Swatch(bright: Colors.purpleAccent, dark: Colors.greenAccent),
      progressText: 'Example Showable spinner',
      scaffold: Scaffold(
        appBar: AppBar(
          title: Text('Title: example'),
        ),
        body: body(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              hideSpinner = false;
              ++counter;
              tableName = 'table$counter';
              Future.delayed(Duration(seconds: 3), () {
                setState(() {
                  hideSpinner = true;
                });
              });
            });
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(Widget oldWidget) {
    Log.t('example didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('example deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('example dispose');
    WidgetsBinding.instance.removeObserver(this);
    inputCompleteStream.dispose();
    keyboardVisibilityNotification.dispose();
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    Log.v('body() didChangeDependencies => $listHeight');
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        tabletInputLine,
//        DisplayRecordsWidget(
//          sink: inputSelectedStream.sink,
//          tables: listOfTables,
//        ),
        projectBloc == null
            ? CircularProgressIndicator()
            : Container(
                height: listHeight,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: DBRecord.dataColumns(context),
                    rows: projectBloc.dataRows(context, sink: inputSelectedStream.sink, style: null),
                  ),
                ),
              ),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WideAnimatedButton(
                caption: 'Write',
                colors: ModeThemeData.productSwatch,
                onTap: (tap, timestamp) {
                  if (projectBloc == null) return;
                  projectBloc.writeTablesToFile(prettyPrint: true).then((_) {
                    setState(() {
                      caption = 'Done!!';
                      expand();
                    });
                  });
                },
                height: 60.0,
                width: 200,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WideAnimatedButton(
                caption: caption,
                colors: ModeThemeData.primarySwatch,
                onLongPress: (event, timeStamp) {
                  make();
                },
                height: 60.0,
                width: 200.0,
              ),
            ),
          ],
        )
      ],
    );
  }

  void make() async {
    if (projectBloc == null) {
      projectBloc = await DBProjectBloc.make('BigTest');
    }
    setState(() {
      listOfTables = projectBloc.sortedTableList();
      caption = 'Ready';
    });
  }

  void listener() async {
    /// DBRecord returned by UI when a record is selected
    /// Redraws the input line with that data
    inputSelectedStream.stream.listen((dbRecord) {
      try {
        assert(dbRecord != null);
        fieldInput?.dispose();
        fieldInput = FieldInput.fromDB(record: dbRecord);
        tableName = dbRecord.name;
        setState(() {
          tabletInputLine = TabletInputLine(fieldInput: fieldInput, sink: inputCompleteStream.sink);
        });
      } catch (err) {
        Log.e(err.toString());
      }
    });

    inputCompleteStream.stream.listen((event) {
      try {
        projectBloc.add(fieldInput: event, toTable: tableName);
        setState(() {
          tabletInputLine = TabletInputLine(fieldInput: FieldInput(), sink: inputCompleteStream.sink);
          listOfTables = projectBloc.sortedTableList();
        });
      } catch (err) {
        Log.e(err.toString());
      }
    });
  }

  void expand() {
    setState(() {
      listHeight = ScreenSize.height * 0.70;
      Log.v('main.dart expand $listHeight');
    });
  }
}
