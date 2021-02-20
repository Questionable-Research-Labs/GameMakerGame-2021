import 'package:flutter/material.dart';

class AppState {
  bool test;
  String location;
  int teamID;
  int playerID;

  AppState({this.test = false});

  AppState.fromAppState(AppState another) {
    test = another.test;
    location = another.location;
    teamID = another.teamID;
    playerID = another.playerID;
  }
}
