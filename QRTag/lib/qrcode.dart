import 'dart:convert';

/// A object storing the data of the json QR Codes
class QRCode {
  /// QR Code type
  String type;
  /// ID from code
  int id;
  /// Time of Scan
  String tos;

  QRCode(this.type, this.id, this.tos);

  factory QRCode.fromJson(String jsonRaw) {
    final json = jsonDecode(jsonRaw);
    print(json);
    return QRCode(
      json['type'],
      json['id'],
      new DateTime.now().toIso8601String()
    );
  }

  @override
  String toString() {
    return '{ ${this.type}, ${this.id}, ${this.tos} }';
  }
}

/// A object storing the data of the json QR Codes
class UIEventMessage {
  /// QR Code type
  String text;
  /// ID from code
  String type;
  /// Time of Event
  DateTime toe;

  UIEventMessage(this.text, this.type, this.toe);
}