import 'package:flutter/material.dart';

import 'model/app_state.dart';
import 'store/store.dart' as appstore;

Future<void> genWrongQRCodeDialog(
    BuildContext context, String typeNeeded) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Wrong QR Code type'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                  'Sorry but that was not the correct type of QR Code, it needs to be: $typeNeeded'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> errorDialog(BuildContext context, String text) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Error!'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(text ?? "Unkown Error"),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

void showSnackBar(BuildContext context, String text) {
  // Find the Scaffold in the widget tree and use
  // it to show a SnackBar.
  Scaffold.of(context).showSnackBar(SnackBar(
    content: Text(text ?? ""),
  ));
}

bool isNumeric(String s) {
  if (s == null) {
    return false;
  }
  return int.parse(s, onError: (e) => null) != null;
}

AppState getState() {
  final store = appstore.store;
  return store.state;
}
