import 'package:web_socket_channel/io.dart';

import '../qrcode.dart';
/// Actions with Payload

class Location {
  final String payload;
  Location(this.payload);
}

class TeamID {
  final int payload;
  TeamID(this.payload);
}

class PlayerID {
  final int payload;
  PlayerID(this.payload);
}

class Username {
  final String payload;
  Username(this.payload);
}

class PlayerNumbers {
  final String payload;
  PlayerNumbers(this.payload);
}

class WebSocketChannel {
  final IOWebSocketChannel payload;
  WebSocketChannel(this.payload);
}

class SocketReady {
  final bool payload;
  SocketReady(this.payload);
}

class CurrentlyDeactivated {
  final bool payload;
  CurrentlyDeactivated(this.payload);
}

class HomeBaseStolen {
  final bool payload;
  HomeBaseStolen(this.payload);
}

class RediedUp {
  final bool payload;
  RediedUp(this.payload);
}

class QRCodeQueue {
  final Map<String, QRCode> payload;
  QRCodeQueue(this.payload);
}