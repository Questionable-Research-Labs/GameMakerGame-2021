import 'package:QRTag/model/app_state.dart';
import 'package:QRTag/qrcode.dart';
import 'package:QRTag/store/actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:redux/redux.dart';
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
  final socket = IOWebSocketChannel.connect("ws://localhost:4003");
  socket.stream.listen((message) {
    dynamic data = jsonDecode(message);
    print("New message from websocket: "+message);
    if (data["message"] == "ready") {
      store.dispatch(SocketReady(true));
    }
  });
  socket.sink.done.then((v) {
    print("WEBSOCKET EXITED");
  });
  store.dispatch(WebSocketChannel(socket));
  store.dispatch(SocketReady(false));
}

AppState getState() {
  final store = appstore.store;
  print("Got State!");
  print(store.state);
  return store.state;
}