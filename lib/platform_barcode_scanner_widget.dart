import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class PlatformBarcodeScannerWidget extends StatelessWidget {
  final ScanParam param;

  PlatformBarcodeScannerWidget({Key? key, required this.param})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: "com.flutter_to_barcode_scanner_view",
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: param.toMap(),
      );
    } else {
      return AndroidView(
          viewType: "barcode_android_view",
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: param.toMap());
    }
  }
}

class ScanParam {
  double height;
  int scanType;
  static const int SCAN_BARCODE = 1;
  static const int SCAN_QRCODE = 2;

  ScanParam(this.height, this.scanType);

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = Map();
    map["height"] = height.toString();
    map["scanType"] = scanType.toString();
    return map;
  }
}
