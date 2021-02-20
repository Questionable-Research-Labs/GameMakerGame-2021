import 'package:QRTag/gameview.dart';
import 'package:QRTag/model/app_state.dart';
import 'package:QRTag/qrcode.dart';
import 'package:QRTag/store/actions.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'main.dart';

import 'utill.dart';
import 'store/store.dart' as appstore;
// import 'package:flutter_redux/flutter_redux.dart';

Future<void> readyToPlay(state) async {}

Future joinGame() async {
  var state = getState();
  if (!state.socketReady) {
    print("Instantiating WebSocket");
    initWS();
    state = getState();
  }
  
  state.webSocketChannel.sink.add(jsonEncode(<String, dynamic>{
      "message": "join",
      "userID": state.playerID,
      "username": state.username,
      "team": state.teamID
    }));
    print("WEB SOCKET STATUS");

    var result = await state.webSocketChannel.stream.single;
    var json = jsonDecode(result);

    if (json["message"] == "joined") {
      if (json["status"] == "accepted") {
        return Future.value();
      } else {
        return Future.error(json["status"]);
      }
    } else {
      return Future.error("The API be vibin");
    }
}

Future scanPlayer(QRCode qrCode) async {
  print(qrCode.toString());
}
Future scanBase(QRCode qrCode) async {
  print(qrCode.toString());
} 

Future initWS() async {
  final store = appstore.store;
  final socket = IOWebSocketChannel.connect("ws://qrtag.qrl.nz:4003");
  socket.stream.listen((message) {
    dynamic data = jsonDecode(message);
    handleMessage(data);
  });
  socket.sink.done.then((v) {
    print("WEBSOCKET EXITED");
  });
  store.dispatch(WebSocketChannel(socket));
  store.dispatch(SocketReady(false));
}

Future sendScan(QRCode code) async {
  final store = appstore.store;
  final socket = store.state.webSocketChannel;
  final message = <String, dynamic>{
    "message": "scan",
    "id": code.id,
    "type": code.type,
    "time": code.tos,
  };

  socket.sink.add(jsonEncode(message));

  var result = jsonDecode(await socket.stream.single);

  if (["not active", "bad scan", "no such base"].contains(result['message'])) {
    Future.error(result['message']);
  } else {
    handleMessage(result);
  }
}

void handleMessage(Map<String, dynamic> data) {
  final store = appstore.store;
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

      break;

    default:
      print("Unimplemented message received");
  }
}