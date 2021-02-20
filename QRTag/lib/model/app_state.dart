import 'package:flutter/material.dart';

class AppState {
  bool test;
  String location;

  AppState(
      {this.test = false, this.location = ""});

  AppState.fromAppState(AppState another) {
    test = another.test;
    location = another.location;
  }
}