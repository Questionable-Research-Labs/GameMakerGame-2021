import 'package:QRTag/model/app_state.dart';
import 'package:QRTag/store/actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:redux/redux.dart';
// import 'package:flutter_redux/flutter_redux.dart';

Future<void> readyToPlay(state) async {}

Future joinGame(BuildContext context,Store store) async {
  final state = getState(context, store);
  if (!state.socketReady) {
    print("Instantiating WebSocket");
    initWS(context, store);
  }
  state.webSocketChannel.sink.add(jsonEncode(<String, dynamic>{
      "message": "join",
      "userID": state.playerID,
      "username": state.username,
      "team": state.teamID
    }));

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

Future initWS(BuildContext context,Store store) async {
  final socket = IOWebSocketChannel.connect("ws://localhost:4003");
  socket.stream.listen((message) {
    dynamic data = jsonDecode(message);

    if (data["message"] == "ready") {
      store.dispatch(SocketReady(true));
    }
  });
  store.dispatch(WebSocketChannel(socket));
  store.dispatch(SocketReady(false));

}

AppState getState(BuildContext context,Store store) {
  print("Got State!");
  print(store.state);
  return store.state;
}