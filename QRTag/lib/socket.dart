import 'dart:convert';
import 'dart:async';
import 'dart:html';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:uuid/uuid.dart';

import 'main.dart';
import 'utill.dart';
import 'qrcode.dart';
import 'store/store.dart' as appstore;
import 'store/actions.dart';

// import 'package:flutter_redux/flutter_redux.dart';
typedef Future RequestCallback(Map<String, dynamic> data);
Map<String, RequestCallback> handlerLookup = {};

Future<void> readyToPlay(state) async {}

Future joinGame(BuildContext context) async {
  print("Attempting to join game...");
  var state = getState();
  print("Readying!");

  final uuid = Uuid();
  final requestUUID = uuid.v4();

  if (!state.socketReady) {
    print("Instantiating WebSocket");
    await initWS();
    state = getState();
  }
  handlerLookup[requestUUID] = (data) async {
    print("Callback:" + data.toString());
    if (data["status"] != "accepted") {
      errorDialog(context, data["status"]);
    } else {
      appstore.store.dispatch(RediedUp(true));
      if (data["message"] == "joined start game") {
        print("Immediate start");
        startGame();
      }
      
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

Future exitGame() async {
  var state = getState();
  await state.webSocketChannel.sink.close();
  appstore.store.dispatch(SocketReady(false));
  appstore.store.dispatch(WebSocketChannel(null));
  appstore.store.dispatch(RediedUp(false));
  return;
}

Future initWS() async {
  final store = appstore.store;
  final socket = IOWebSocketChannel.connect("ws://192.168.10.136:4003");
  socket.stream.listen((message) {
    dynamic data = jsonDecode(message);
    handleMessage(data);
  }, onDone: () => appstore.store.dispatch(SocketReady(false)), onError: (e) => {print(e)} );
  socket.sink.done.then((v) {
    print("WEBSOCKET EXITED");
  });

  store.dispatch(WebSocketChannel(socket));
  store.dispatch(SocketReady(false));
}

Future sendScan(QRCode code) async {
  var state = getState();
  final context = state.messageQueue;
  final uuid = Uuid();
  final requestUUID = uuid.v4();

  if (!state.socketReady) {
    print("Instantiating WebSocket");
    initWS();
    state = getState();
  }
  handlerLookup[requestUUID] = (data) async {
    print("Callback:" + data.toString());
    if (data.containsKey("error") || !data.containsKey("message")) {
      // errorDialog(context, data["message"]);
      var newMessageQueue = state.messageQueue;
      newMessageQueue.add(UIEventMessage(data["message"] ?? "Unkown error while scanning QR Code","error",DateTime.now()));
      appstore.store.dispatch(MessageQueue(newMessageQueue));
    } else {
      switch (data["message"]) {
        case "point scored":
          break;
        case "sucessfull tag":
          print("Gamer");
          var newMessageQueue = state.messageQueue;
          newMessageQueue.add(UIEventMessage(data["message"],"info",DateTime.now()));
          appstore.store.dispatch(MessageQueue(newMessageQueue));
          print("Added QR Code to Queue");
          print(newMessageQueue);
          // showSnackBar(context, "You scanned $data['username'] in team $data['team']!");
          break;
        default:
          break;
      }
    }
  };

  state.webSocketChannel.sink
      .add(jsonEncode({"message": "scan", "id": code.id, "type": code.type, "time": code.tos, "uuid": requestUUID}));
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
      startGame();
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

void startGame () {
  navigatorKey.currentState.pushNamed('/game');
}

void instantiateSockets () {
  print("Starting Websocket Timer");
  new Timer.periodic(Duration(milliseconds: 200), (Timer t) => qrCodeScanManager() );
  new Timer.periodic(Duration(milliseconds: 500), (Timer t) => wsDisconectManager() );
}

void qrCodeScanManager () {
  final state = getState();
  if (state.qrCodeQueue != null) {return;}
  
  if (state.qrCodeQueue.length > 0) {
    print("Processing QR Codes");
    print(state.qrCodeQueue);
    state.qrCodeQueue.forEach((key, value) {
      sendScan(value);
    });
    appstore.store.dispatch(QRCodeQueue({}));
  }
}
void wsDisconectManager () {
  final state = getState();
  if (!state.socketReady) {
    print("Web Socket Disconected, attempting to reconect...");
    initWS();
  }
}