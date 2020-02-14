import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_db_input_widget/flutter_db_input_widget.dart';
import 'package:flutter_db_input_widget/model/db_record.dart';
import 'package:flutter_theme_package/flutter_theme_package.dart';
import 'package:flutter_tracers/trace.dart' as Log;
import 'package:keyboard_visibility/keyboard_visibility.dart';

void main() => runApp(MyApp());

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

  String caption = 'Generate';
  FieldInput fieldInput = FieldInput();
  bool hideSpinner = true;
  InputCompleteStream inputCompleteStream = InputCompleteStream();
  InputSelectedStream inputSelectedStream = InputSelectedStream();
  KeyboardVisibilityNotification keyboardVisibilityNotification = KeyboardVisibilityNotification();
  double listHeight = 300.0;
  List<DBRecord> listOfTables = List();
  DBProjectBloc projectBloc;
  FocusNode projectFocusNode = FocusNode(debugLabel: 'project');
  bool projectStart = false;
  FocusNode tableNameFocusNode = FocusNode(debugLabel: 'table');
  TextEditingController tableTextEditingController = TextEditingController();
  String tableName;
  TabletInputLine tabletInputLine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Log.t('main.dart initState');
    tabletInputLine = TabletInputLine(key: tabletInputLineKey, fieldInput: fieldInput, sink: inputCompleteStream.sink);
    keyboardVisibilityNotification.addNewListener(onShow: () {
      setState(() {
        listHeight = ScreenSize.height * 0.60;
        Log.f('main.dart show listHeight $listHeight');
      });
    }, onHide: () {
      Log.f('example onHide');
      expand();
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    Log.t('main.dart didChangeDependencies');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Log.t('main.dart didChangeAppLifecycleState ${state.toString()}');
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = WidgetsBinding.instance.window.platformBrightness;
    ModeTheme.of(context).setBrightness(brightness);
    Log.t('main.dart didChangePlatformBrightness ${brightness.toString()}');
  }

  @override
  void afterFirstLayout(BuildContext context) {
    Log.t('main.dart afterFirstLayout');
    expand();
    listener();
  }

  @override
  Widget build(BuildContext context) {
    Log.t('main.dart build');
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
    Log.t('main.dart didUpdateWidget');
    super.didUpdateWidget(oldWidget);
  }

  @override
  void deactivate() {
    Log.t('main.dart deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    Log.t('main.dart dispose');
    WidgetsBinding.instance.removeObserver(this);
    inputCompleteStream.dispose();
    keyboardVisibilityNotification.dispose();
    fieldInput.dispose();
    super.dispose();
  }

  /// Scaffold body
  Widget body() {
    Log.t('main.dart body() didChangeDependencies => $listHeight');
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        /// Buttons at the top
        Row(
          children: [
            Padding(
              child: WideAnimatedButton(
                playSystemClickSound: true,
                caption: 'Start',
                colors: ModeThemeData.productSwatch,
                height: 60.0,
                onTap: (tap, timestamp) {
                  setState(() {
                    projectStart = true;
                    setFocusOn(projectFocusNode);
                  });
                },
                width: 200,
              ),
              padding: const EdgeInsets.all(8.0),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: WideAnimatedButton(
                caption: 'Save',
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
                  Generator(
                          callback: (message) {
                            setState(() {
                              caption = message;
                            });
                            Log.v(message, false, '~');
                            return true;
                          },
                          projectBloc: projectBloc)
                      .start();
                },
                height: 60.0,
                width: 400.0,
              ),
            ),
          ],
        ),

        ///Project input field, table name input field
        Row(
          children: <Widget>[
            Container(
              child: Opacity(
                child: NameInputForm(
                  focusNode: projectFocusNode,
                  formText: projectBloc?.name ?? '',
                  invalidInput: (_) {
                    setState(() {
                      tableName = null;
                    });
                  },
                  title: 'Project',
                  result: (newName) {
                    projectBloc?.writeTablesToFile(prettyPrint: true);
                    DBProjectBloc.make(newName).then((newBloc) {
                      projectBloc = newBloc;
                      setState(() {
                        listOfTables = projectBloc.sortedTableList();
                        tableName = '';
                        setFocusOn(tableNameFocusNode);
                      });
                    });
                  },
                ),
                opacity: (projectStart) ? 1.0 : 0.2,
              ),
              width: ScreenSize.width * 0.20,
            ),
            Container(
              width: 25,
            ),
            Opacity(
              child: Container(
                  child: NameInputForm(
                      controller: tableTextEditingController,
                      focusNode: tableNameFocusNode,
                      formText: tableName ?? '',
                      invalidInput: (badName) {
                        setState(() {
                          tableName = badName;
                        });
                      },
                      title: 'Table',
                      result: (newTableName) {
                        setState(() {
                          tableName = newTableName.substring(0, 1).toUpperCase() + newTableName.substring(1);
                          fieldInput.focusOnFirstField(context);
                        });
                      }),
                  width: ScreenSize.width * 0.20),
              opacity: (tableName == null) ? 0.2 : 1.0,
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
        ),

        /// Data input line
        Opacity(
          child: tabletInputLine,
          opacity: (FieldInput.validateInputField(name: tableName) == null) ? 1.0 : 0.2,
        ),

        /// Table of data
        Opacity(
          child: Container(
            height: listHeight,
            child: SingleChildScrollView(
              child: (projectBloc != null)
                  ? DataTable(
                      columns: DBRecord.dataColumns(context),
                      rows: projectBloc.dataRows(
                        context,
                        preferTable: (tableName ?? '').toLowerCase(),
                        sink: inputSelectedStream.sink,
                        style: null,
                      ))
                  : Container(),
            ),
          ),
          opacity: (projectBloc == null) ? 0.2 : 1.0,
        ),
      ],
    );
  }

  void listener() async {
    /// DBRecord returned by UI when a record is selected
    /// Redraws the input line with that data
    inputSelectedStream.stream.listen((dbRecord) {
      try {
        assert(dbRecord != null);
        setState(() {
          fieldInput.copyFromDB(context: context, record: dbRecord);
          tabletInputLineKey.currentState.setVisibility(fieldInput);
          tableName = dbRecord.name;
          projectBloc.remove(dbRecord: dbRecord);
          tableTextEditingController.text = tableName;
        });
      } catch (err) {
        Log.e(err.toString());
      }
    });

    /// Listener when a data line has been completed and ready to add to the list of fields for a table in a project
    /// and reset for another field.
    inputCompleteStream.stream.listen((event) {
      try {
        projectBloc.add(fieldInput: event, toTable: tableName);
        setState(() {
          projectBloc.writeTablesToFile(prettyPrint: true);
          listOfTables = projectBloc.sortedTableList(tableName);
          fieldInput.reset(context: context);
        });
      } catch (err) {
        Log.e(err.toString());
      }
    });
  }

  void expand() {
    setState(() {
      listHeight = ScreenSize.height * 0.60;
      Log.f('main.dart expand $listHeight');
    });
  }

  void setFocusOn(FocusNode node) {
    Future.delayed(Duration(milliseconds: 500), () {
      Log.t('main.dart setFocus on $node');
      FocusScope.of(context).requestFocus(node);
      FocusScope.of(context).requestFocus(node);
    });
  }
}
