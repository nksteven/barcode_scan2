import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class PlatformBarcodeScannerWidget extends StatelessWidget {
  const PlatformBarcodeScannerWidget({Key? key, required this.param})
      : super(key: key);

  final ScanParam param;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'com.flutter_to_barcode_scanner_view',
        creationParamsCodec: const StandardMessageCodec(),
        creationParams: param.toMap(),
      );
    } else {
      return AndroidView(
          viewType: 'barcode_android_view',
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: param.toMap());
    }
  }
}

class ScanParam {
  ScanParam(this.height, this.scanType);

  double height;
  int scanType;
  static const int SCAN_BARCODE = 1;
  static const int SCAN_QRCODE = 2;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['height'] = height.toString();
    map['scanType'] = scanType.toString();
    return map;
  }
}
