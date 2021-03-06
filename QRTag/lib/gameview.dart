import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:QRTag/qrcode.dart';
import 'package:QRTag/store/actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'qrview.dart';
import 'utill.dart';
import 'socket.dart';
import 'store/actions.dart';
import 'store/store.dart' as appstate;

Future<void> handleQRCode(QRCode qrCode, BuildContext context) async {
  var qrCodeQueue = getState().qrCodeQueue;
  if (qrCodeQueue == null) {
    qrCodeQueue = {};
  }
  final scanDataID = qrCode.type+qrCode.id.toString();
  if (!qrCodeQueue.containsKey(scanDataID)) {
    qrCodeQueue[qrCode.type+qrCode.id.toString()] = qrCode;
    print("New Scan and making the QR Code view look like this:");
    print(qrCodeQueue);
    appstate.store.dispatch(QRCodeQueue(qrCodeQueue));
  } else {
    print("QR Code Scanned but it is already in the database of scans to send next!");
  }
  
}

class GameViewScafold extends StatefulWidget {
  GameViewScafold({Key key, this.title = "Game"}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _GameViewScafoldState createState() => _GameViewScafoldState();
}

class _GameViewScafoldState extends State<GameViewScafold> {
  

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title ?? ""),
        ),
        body: GameView()
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            
        );
  }
}

class GameView extends StatefulWidget {
  @override
  _GameViewState createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  dynamic _permissionStatus;
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'GameView');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      print(controller);
      controller.pauseCamera();
    }
    controller.resumeCamera();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(onLayoutDone);
  }

  void onLayoutDone(Duration timeStamp) async {
    _permissionStatus = await Permission.camera.status;
    setState(() {});
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      // Found QR Code
      print("QR CODE FOUND: ");
      print(scanData.format);
      print(scanData.code);
      
      // Check if valid QR code
      try {
        var softwareCJFixes = scanData.code.replaceAll("http://", "");
        print(softwareCJFixes.substring(softwareCJFixes.length - 1, softwareCJFixes.length ));
        if (softwareCJFixes.substring(softwareCJFixes.length - 1, softwareCJFixes.length )!="}") {softwareCJFixes+="}";}
        handleQRCode(QRCode.fromJson(softwareCJFixes), context);
        
        
      } on FormatException catch (e) {
        print('The QR Code is not valid JSON');
        print(e);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
                margin: const EdgeInsets.only(left: 20.0, right: 20.0),
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Expanded(flex: 4, child: _buildQrView(context)),
                ]));
  }
}