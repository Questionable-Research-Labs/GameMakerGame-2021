/// A object storing the data of the json QR Codes
class QRCode {
  /// QR Code type
  String type;
  /// ID from code
  dynamic id;
  /// Time of Scan
  DateTime tos;

  QRCode(this.type, this.id, this.tos);

  factory QRCode.fromJson(dynamic json) {
    return QRCode(json['type'] as String, json['id'], new DateTime.now());
  }

  @override
  String toString() {
    return '{ ${this.type}, ${this.id}, ${this.tos} }';
  }
}