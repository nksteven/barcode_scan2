import 'dart:async';
import 'dart:io' show Platform;

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:barcode_scan2/platform_barcode_scanner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MaterialApp(
      title: 'App',
      home: App(),
    ));

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  ScanResult? scanResult;

  final _flashOnController = TextEditingController(text: 'Flash on');
  final _flashOffController = TextEditingController(text: 'Flash off');
  final _cancelController = TextEditingController(text: 'Cancel');

  var _aspectTolerance = 0.00;
  var _numberOfCameras = 0;
  var _selectedCamera = -1;
  var _useAutoFocus = true;
  var _autoEnableFlash = false;

  static final _possibleFormats = BarcodeFormat.values.toList()
    ..removeWhere((e) => e == BarcodeFormat.unknown);

  List<BarcodeFormat> selectedFormats = [..._possibleFormats];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      _numberOfCameras = await BarcodeScanner.numberOfCameras;
      setState(() {});
    });
  }

  List<Widget> demoExampleCodeWidget() {
    final scanResult = this.scanResult;
    return [
      if (scanResult != null)
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                title: const Text('Result Type'),
                subtitle: Text(scanResult.type.toString()),
              ),
              ListTile(
                title: const Text('Raw Content'),
                subtitle: Text(scanResult.rawContent),
              ),
              ListTile(
                title: const Text('Format'),
                subtitle: Text(scanResult.format.toString()),
              ),
              ListTile(
                title: const Text('Format note'),
                subtitle: Text(scanResult.formatNote),
              ),
            ],
          ),
        ),
      const ListTile(
        title: Text('Camera selection'),
        dense: true,
        enabled: false,
      ),
      RadioListTile(
        onChanged: (v) => setState(() => _selectedCamera = -1),
        value: -1,
        title: const Text('Default camera'),
        groupValue: _selectedCamera,
      ),
      ...List.generate(
        _numberOfCameras,
        (i) => RadioListTile(
          onChanged: (v) => setState(() => _selectedCamera = i),
          value: i,
          title: Text('Camera ${i + 1}'),
          groupValue: _selectedCamera,
        ),
      ),
      const ListTile(
        title: Text('Button Texts'),
        dense: true,
        enabled: false,
      ),
      ListTile(
        title: TextField(
          decoration: const InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Flash On',
          ),
          controller: _flashOnController,
        ),
      ),
      ListTile(
        title: TextField(
          decoration: const InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Flash Off',
          ),
          controller: _flashOffController,
        ),
      ),
      ListTile(
        title: TextField(
          decoration: const InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: 'Cancel',
          ),
          controller: _cancelController,
        ),
      ),
      if (Platform.isAndroid) ...[
        const ListTile(
          title: Text('Android specific options'),
          dense: true,
          enabled: false,
        ),
        ListTile(
          title: Text(
            'Aspect tolerance (${_aspectTolerance.toStringAsFixed(2)})',
          ),
          subtitle: Slider(
            min: -1,
            max: 1,
            value: _aspectTolerance,
            onChanged: (value) {
              setState(() {
                _aspectTolerance = value;
              });
            },
          ),
        ),
        CheckboxListTile(
          title: const Text('Use autofocus'),
          value: _useAutoFocus,
          onChanged: (checked) {
            setState(() {
              _useAutoFocus = checked!;
            });
          },
        ),
      ],
      const ListTile(
        title: Text('Other options'),
        dense: true,
        enabled: false,
      ),
      CheckboxListTile(
        title: const Text('Start with flash'),
        value: _autoEnableFlash,
        onChanged: (checked) {
          setState(() {
            _autoEnableFlash = checked!;
          });
        },
      ),
      const ListTile(
        title: Text('Barcode formats'),
        dense: true,
        enabled: false,
      ),
      ListTile(
        trailing: Checkbox(
          tristate: true,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: selectedFormats.length == _possibleFormats.length
              ? true
              : selectedFormats.isEmpty
                  ? false
                  : null,
          onChanged: (checked) {
            setState(() {
              selectedFormats = [
                if (checked ?? false) ..._possibleFormats,
              ];
            });
          },
        ),
        dense: true,
        enabled: false,
        title: const Text('Detect barcode formats'),
        subtitle: const Text(
          'If all are unselected, all possible '
          'platform formats will be used',
        ),
      ),
      ..._possibleFormats.map(
        (format) => CheckboxListTile(
          value: selectedFormats.contains(format),
          onChanged: (i) {
            setState(() => selectedFormats.contains(format)
                ? selectedFormats.remove(format)
                : selectedFormats.add(format));
          },
          title: Text(format.toString()),
        ),
      ),
    ];
  }

  Future<void> _scan() async {
    try {
      final result = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': _cancelController.text,
            'flash_on': _flashOnController.text,
            'flash_off': _flashOffController.text,
          },
          restrictFormat: selectedFormats,
          useCamera: _selectedCamera,
          autoEnableFlash: _autoEnableFlash,
          android: AndroidOptions(
            aspectTolerance: _aspectTolerance,
            useAutoFocus: _useAutoFocus,
          ),
        ),
      );
      setState(() => scanResult = result);
    } on PlatformException catch (e) {
      setState(() {
        scanResult = ScanResult(
          type: ResultType.Error,
          format: BarcodeFormat.unknown,
          rawContent: e.code == BarcodeScanner.cameraAccessDenied
              ? 'The user did not grant the camera permission!'
              : 'Unknown error: $e',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera),
            tooltip: 'Scan',
            onPressed: _scan,
          )
        ],
      ),
      body: ListView(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final permissionsRequested =
                  await BarcodeScanner.requestCameraPermission();
              if (permissionsRequested == 1) {
                await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const CustomBarcodeScanner()));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(top: 200),
              alignment: Alignment.center,
              height: 60,
              child: const Text('Custom Scanner View'),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomBarcodeScanner extends StatefulWidget {
  const CustomBarcodeScanner({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CustomBarcodeState();
  }
}

class _CustomBarcodeState extends State<CustomBarcodeScanner> {
  @override
  void initState() {
    super.initState();
    BarcodeScanner.scannerViewChannel.setMethodCallHandler(methodCallHandler);
  }

  Future<dynamic> methodCallHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'didScanBarcodeAction':
        debugPrint(
            '${methodCall.arguments}'); // prints the argument - "someValue"
        return null; // could return a value here
      default:
        throw PlatformException(code: 'notimpl', message: 'not implemented');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Barcode Scanner'),
          leading: GestureDetector(
            onTap: () async {
              await BarcodeScanner.stopScanning();
              Navigator.of(context).pop();
            },
            child: Container(
              alignment: Alignment.center,
              height: 40,
              child: const Text('Back'),
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            SizedBox(
              height: 200,
              child: PlatformBarcodeScannerWidget(
                param: ScanParam(200, ScanParam.SCAN_BARCODE),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (_, index) {
                  return ListTile(
                    title: Text('Title: $index'),
                  );
                },
              ),
            ),
          ],
        ));
  }
}
