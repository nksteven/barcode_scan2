//
//  FlutterBarcodeScannerView.h
//  barcode_scan
//
//  Created by ZhouYuan on 2020/6/5.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FlutterBarcodeScannerViewDelegate <NSObject>

- (void)didScanBarcodeWithResult:(NSString*) result;
- (void)cameraDenied:(bool) permission;

@end

@interface FlutterBarcodeScannerView : NSObject<FlutterPlatformView>

- (instancetype)initWithWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args;

@property (weak, nonatomic) id<FlutterBarcodeScannerViewDelegate> delegate;

- (void) stopScanning;
- (void) startScanning;

- (void) pauseScanning;
- (void) resumeScanning;

@end

NS_ASSUME_NONNULL_END
