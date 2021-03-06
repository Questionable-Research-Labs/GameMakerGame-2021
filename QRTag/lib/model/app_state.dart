import 'dart:html';

import 'package:QRTag/qrcode.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:web_socket_channel/io.dart';

class AppState {
  String location;
  int teamID;
  int playerID;
  String username;
  Tuple2<int,int> playerNumbers; // <playersReady,playersTotal>
  IOWebSocketChannel webSocketChannel;
  bool socketReady;
  bool currentlyDeactivated;
  bool homeBaseStolen;
  bool readiedUp;
  Map<String, QRCode> qrCodeQueue;
  List<UIEventMessage> messageQueue;

  AppState({this.playerNumbers = const Tuple2<int,int>(0,1), this.socketReady = false, this.readiedUp = false});

  AppState.fromAppState(AppState another) {
    location = another.location;
    teamID = another.teamID;
    playerID = another.playerID;
    username = another.username;
    playerNumbers = another.playerNumbers;
    webSocketChannel = another.webSocketChannel;
    socketReady = another.socketReady;
    currentlyDeactivated = another.currentlyDeactivated;
    homeBaseStolen = another.homeBaseStolen;
    readiedUp = another.readiedUp;
    qrCodeQueue = another.qrCodeQueue;
    messageQueue = another.messageQueue;
  }
}
