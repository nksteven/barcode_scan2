//
//  FlutterBarcodeScannerViewFactory.m
//  barcode_scan
//
//  Created by ZhouYuan on 2020/6/5.
//

#import "FlutterBarcodeScannerViewFactory.h"
#import "FlutterBarcodeScannerView.h"
#import <MTBBarcodeScanner/MTBBarcodeScanner.h>

@interface FlutterBarcodeScannerViewFactory() <FlutterPlatformViewFactory, FlutterBarcodeScannerViewDelegate>

@property (nonatomic, weak) FlutterBarcodeScannerView* barcodeScannerView;
@property (nonatomic, strong) FlutterMethodChannel* channel;

@end

@implementation FlutterBarcodeScannerViewFactory

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    if (self) {
        _channel = [FlutterMethodChannel methodChannelWithName:@"com.flutter_to_barcode_scanner_view_channel" binaryMessenger:registrar.messenger];
        [registrar addMethodCallDelegate:self channel: _channel];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"stopScanning" isEqualToString:call.method]) {
        [_barcodeScannerView stopScanning];
        result(@(true));
    } else if ([@"pauseCamera" isEqualToString:call.method]) {
        [_barcodeScannerView pauseScanning];
        result(@(true));
    } else if ([@"resumeCamera" isEqualToString:call.method]) {
        [_barcodeScannerView resumeScanning];
        result(@(true));
    } else if([@"requestCameraPermission" isEqualToString:call.method]) {
        [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
            if (success) {
                result(@(true));
            } else {
                result(@(false));
            }
        }];
    }
}

#pragma mark - FlutterBarcodeScannerViewDelegate
- (void)didScanBarcodeWithResult:(NSString*) result {
    if (_channel) {
        [_channel invokeMethod:@"didScanBarcodeAction" arguments:result];
    }
}

- (void)cameraDenied:(BOOL)result {
    if (_channel) {
        [_channel invokeMethod:@"cameraDenied" arguments:[NSNumber numberWithBool:result]];
    }
}

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    id viewFactory = [[FlutterBarcodeScannerViewFactory alloc]initWithRegistrar:registrar];
    [registrar registerViewFactory:viewFactory withId:@"com.flutter_to_barcode_scanner_view"];
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    _barcodeScannerView = [[FlutterBarcodeScannerView alloc]initWithWithFrame:frame viewIdentifier:viewId arguments:args];
    _barcodeScannerView.delegate = self;
    return _barcodeScannerView;
}

@end
