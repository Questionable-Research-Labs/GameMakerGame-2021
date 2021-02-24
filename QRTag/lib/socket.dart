import 'package:QRTag/gameview.dart';
import 'package:QRTag/model/app_state.dart';
import 'package:QRTag/qrcode.dart';
import 'package:QRTag/store/actions.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';
import 'package:tuple/tuple.dart';

import 'dart:convert';
import 'main.dart';

import 'utill.dart';
import 'store/store.dart' as appstore;

// import 'package:flutter_redux/flutter_redux.dart';
typedef Future RequestCallback(Map<String, dynamic> data);
Map<String, RequestCallback> handlerLookup = {};

Future<void> readyToPlay(state) async {}

Future joinGame(BuildContext context) async {
  print("Attempting to join game...");
  var state = getState();
  if (state.readiedUp == true) {
    print("Un Reading");
    state.webSocketChannel.sink.close();
    appstore.store.dispatch(SocketReady(false));
    appstore.store.dispatch(WebSocketChannel(null));
    appstore.store.dispatch(RediedUp(false));
    return;
  }
  print("Readying!");

  final uuid = Uuid();
  final requestUUID = uuid.v4();

  if (!state.socketReady) {
    print("Instantiating WebSocket");
    initWS();
    state = getState();
  }
  handlerLookup[requestUUID] = (data) async {
    print("Callback:" + data.toString());
    if (data["status"] != "accepted") {
      errorDialog(context, data["status"]);
    } else {
      appstore.store.dispatch(RediedUp(true));
    }
  };
  state.webSocketChannel.sink.add(jsonEncode(<String, dynamic>{
    "message": "join",
    "userID": state.playerID,
    "username": state.username,
    "team": state.teamID,
    "uuid": requestUUID
  }));
  print("Join request sent");
}

Future initWS() async {
  final store = appstore.store;
  final socket = IOWebSocketChannel.connect("ws://qrtag.qrl.nz");
  socket.stream.listen((message) {
    dynamic data = jsonDecode(message);
    handleMessage(data);
  }, onDone: () => wsReconnect(), onError: (_) => wsReconnect());
  socket.sink.done.then((v) {
    print("WEBSOCKET EXITED");
  });

  store.dispatch(WebSocketChannel(socket));
  store.dispatch(SocketReady(false));
}

Future wsReconnect() {
  print("reconnecting");

  appstore.store.dispatch(SocketReady(false));

  initWS();

  return Future.value();
}

Future sendScan(QRCode code, BuildContext context) async {
  var state = getState();
  final uuid = Uuid();
  final requestUUID = uuid.v4();

  if (!state.socketReady) {
    print("Instantiating WebSocket");
    initWS();
    state = getState();
  }
  handlerLookup[requestUUID] = (data) async {
    print("Callback:" + data.toString());
    if (data.containsKey("error")) {
      errorDialog(context, data["message"]);
    } else {
      switch (data["message"]) {
        case "point scored":
          break;
        case "sucessfull tag":
          print("Gamer");
          showSnackBar(
              context, "You scanned $data['username'] in team $data['team']!");
          break;
        default:
          break;
      }
    }
  };

  state.webSocketChannel.sink.add(jsonEncode({
    "message": "scan",
    "id": code.id,
    "type": code.type,
    "time": code.tos,
    "uuid": requestUUID
  }));
  // var result = jsonDecode(await socket.stream.single);

  // if (["not active", "bad scan", "no such base"].contains(result['message'])) {
  //   Future.error(result['message']);
  // } else {
  //   handleMessage(result);
  // }
}

void handleMessage(Map<String, dynamic> data) {
  final store = appstore.store;
  if (data.containsKey("uuid")) {
    if (handlerLookup.containsKey(data["uuid"])) {
      handlerLookup[data["uuid"]](data);
      return;
    }
  }
  switch (data['message']) {
    case "ready":
      store.dispatch(SocketReady(true));
      break;

    case "start game":
      navigatorKey.currentState.pushNamed('/game');

      break;

    case "point scored":
      // team: team that scored the point
      // player: username of the player that scored a point
      print("point scored");

      break;

    case "base receive":
      // baseID: the ID of the base

      break;

    case "base move":
    // team: the team that the player who has the base belongs to
    // username: the players username

    default:
      print("Unimplemented message received");
  }
}
