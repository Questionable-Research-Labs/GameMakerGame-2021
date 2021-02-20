import 'package:flutter/material.dart';

class AppState {
  bool test;

  AppState(
      {@required this.test = false});

  AppState.fromAppState(AppState another) {
    test = another.test;
  }
}