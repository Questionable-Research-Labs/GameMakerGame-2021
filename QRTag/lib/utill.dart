import 'package:flutter/material.dart';

Future<void> genWrongQRCodeDialog(context,typeNeeded) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Wrong QR Code type'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Sorry but that was not the correct type of QR Code, it needs to be: $typeNeeded'),
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

bool isNumeric(String s) {
  if(s == null) {
    return false;
  }
  return int.parse(s, onError: (e) => null) != null;
}