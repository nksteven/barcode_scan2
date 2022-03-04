//
//  FlutterBarcodeScannerViewFactory.h
//  barcode_scan
//
//  Created by ZhouYuan on 2020/6/5.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterBarcodeScannerViewFactory : NSObject <FlutterPlugin>

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end

NS_ASSUME_NONNULL_END
