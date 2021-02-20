import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as websocketSatus;

import 'store/reducer.dart';
import 'store/actions.dart';
import 'model/app_state.dart';

import "qrview.dart";
import "utill.dart";

void main() {
  final Store<AppState> _store =
      Store<AppState>(reducer, initialState: AppState());
  runApp(new MainPage(store: _store));
}

void logError(String code, String message) =>
    print('Error: $code\nError Message: $message');

class MainPage extends StatefulWidget {
  final Store<AppState> store;

  const MainPage({Key key, this.store}) : super(key: key);

  QRTag createState() => QRTag(store);
}

// Root of aplication
class QRTag extends State<MainPage> {
  final Store<AppState> store;
  QRTag(this.store);
  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
        store: store,
        child: MaterialApp(
          title: 'QR Tag',
          theme: ThemeData(
            // This is the theme of your application.
            //
            // Try running your application with "flutter run". You'll see the
            // application has a blue toolbar. Then, without quitting the app, try
            // changing the primarySwatch below to Colors.green and then invoke
            // "hot reload" (press "r" in the console where you ran "flutter run",
            // or simply save your changes to "hot reload" in a Flutter IDE).
            // Notice that the counter didn't reset back to zero; the application
            // is not restarted.

            primarySwatch: Colors.blue,
            // This makes the visual density adapt to the platform that you run
            // the app on. For desktop platforms, the controls will be smaller and
            // closer together (more dense) than on mobile platforms.
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            /* dark theme settings */
            primarySwatch: Colors.blue,
            // This makes the visual density adapt to the platform that you run
            // the app on. For desktop platforms, the controls will be smaller and
            // closer together (more dense) than on mobile platforms.
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: HomePage(title: 'QRTag'),
        ));
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  dynamic _permissionStatus;
  Socket channel;
  Socket socket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(onLayoutDone);

    // final channel = IOWebSocketChannel.connect('ws://echo.websocket.org');
    // channel.sink.add('Hello!');
    // channel.stream.listen((message) {
    //   channel.sink.add('received!');
    //   print(message);
    //   channel.sink.close(websocketSatus.goingAway);
    // });
  }

  

  Future<void> _getQRLocationInfo(BuildContext context, store) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => QRPage(title: "Scan the location QR code")),
    );
    print(result);
    if (result["type"] == "location") {
      store.dispatch(
        Location(result["id"])
      );
    } else {
      await genWrongQRCodeDialog(context,"Location QR Code");
    }
  }
  Future<void> _getQRTeamID(BuildContext context, store) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => QRPage(title: "Scan your Team's flag QR code")),
    );
    print(result);
    if (result["type"] == "base" && isNumeric(result["id"])) {
      store.dispatch(
        TeamID(int.parse(result["id"]))
      );
    } else {
      await genWrongQRCodeDialog(context,"Team Flag QR Code");
    }
  }
  Future<void> _getQRPlayerID(BuildContext context, store) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => QRPage(title: "Scan your personal Player ID QR code")),
    );
    print(result);
    if (result["type"] == "player" && isNumeric(result["id"])) {
      store.dispatch(
        PlayerID(result["id"])
      );
    } else {
      await genWrongQRCodeDialog(context,"Personal Player ID QR Code");
    }
  }

  void onLayoutDone(Duration timeStamp) async {
    _permissionStatus = await Permission.camera.status;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Container(
          margin: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // ****************
              // Location Scanner
              // ****************
              Container(
                margin: const EdgeInsets.all(15.0),
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Location:",style: TextStyle(fontWeight: FontWeight.bold)),
                    StoreConnector<AppState, AppState>(
                        converter: (store) => store.state,
                        builder: (context, store) {
                          return Text(store.location ?? "");
                        }),
                    ButtonBar(
                      children: [
                        StoreConnector<AppState, Store>(
                            converter: (store) {
                              return store;
                              // return () => store.dispatch(Location("QRL"));
                            },
                            builder: (context, store) {
                              return RaisedButton(
                                onPressed: store.state.location!=null ? () {store.dispatch(Location(null));} : null,
                                child: Text("Clear")
                                );
                            }),
                        StoreConnector<AppState, VoidCallback>(
                            converter: (store) {
                              return () => _getQRLocationInfo(context, store);
                            },
                            builder: (context, callback) {
                              return RaisedButton(
                                child: Text("Scan Now"),
                                onPressed: callback,
                              );
                            }),
                      ],
                    )
                  ],
                ),
              ),
              // ****************
              // Team Scanner
              // ****************
              Container(
                margin: const EdgeInsets.all(15.0),
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Team:",style: TextStyle(fontWeight: FontWeight.bold)),
                    StoreConnector<AppState, AppState>(
                        converter: (store) => store.state,
                        builder: (context, store) {
                          return Text(store.teamID ?? "");
                        }),
                    ButtonBar(
                      children: [
                        StoreConnector<AppState, Store>(
                            converter: (store) {
                              return store;
                            },
                            builder: (context, store) {
                              return RaisedButton(
                                onPressed: store.state.teamID!=null ? () {store.dispatch(TeamID(null));} : null,
                                child: Text("Clear")
                                );
                            }),
                        StoreConnector<AppState, VoidCallback>(
                            converter: (store) {
                              return () => _getQRTeamID(context, store);
                            },
                            builder: (context, callback) {
                              return RaisedButton(
                                child: Text("Scan Now"),
                                onPressed: callback,
                              );
                            }),
                      ],
                    )
                  ],
                ),
              ),
              // ****************
              // Player ID Scanner
              // ****************
              Container(
                margin: const EdgeInsets.all(15.0),
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Player ID:",style: TextStyle(fontWeight: FontWeight.bold)),
                    StoreConnector<AppState, AppState>(
                        converter: (store) => store.state,
                        builder: (context, store) {
                          return Text(store.playerID ?? "");
                        }),
                    ButtonBar(
                      children: [
                        StoreConnector<AppState, Store>(
                            converter: (store) {
                              return store;
                            },
                            builder: (context, store) {
                              return RaisedButton(
                                onPressed: store.state.playerID!=null ? () {store.dispatch(PlayerID(null));} : null,
                                child: Text("Clear")
                                );
                            }),
                        StoreConnector<AppState, VoidCallback>(
                            converter: (store) {
                              return () => _getQRPlayerID(context, store);
                            },
                            builder: (context, callback) {
                              return RaisedButton(
                                child: Text("Scan Now"),
                                onPressed: callback,
                              );
                            }),
                      ],
                    )
                  ],
                ),
              ),
              
            ],
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
