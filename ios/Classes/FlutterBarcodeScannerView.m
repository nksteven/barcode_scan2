//
//  FlutterBarcodeScannerView.m
//  barcode_scan
//
//  Created by ZhouYuan on 2020/6/5.
//

#import "FlutterBarcodeScannerView.h"
#import <MTBBarcodeScanner/MTBBarcodeScanner.h>

typedef NS_ENUM(NSUInteger, ScanType) {
    Barcode = 1,
    Qrcode
};

CGFloat toTop = 8;
CGFloat toLeft = 30;
NSInteger lineImageViewTag = 2011;
CGFloat lineImageViewHeight = 2;

@interface FlutterBarcodeScannerView() {
    UIView* _view;
    CGFloat _viewHeight;
    NSString* _scanType;
}

@property (strong, nonatomic) MTBBarcodeScanner* scanner;

@end

@implementation FlutterBarcodeScannerView

-(instancetype)initWithWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    if ([super init]) {
        _viewHeight = 200;
        if (args != nil && ![args isKindOfClass:[NSNull class]]) {
            NSDictionary* params = args;
            NSString* height = [params objectForKey:@"height"];
            NSString* scanType = [params objectForKey:@"scanType"];
            if (height != nil && ![height isKindOfClass:[NSNull class]]) {
                _viewHeight = height.floatValue;
            }
            if (scanType != nil && ![scanType isKindOfClass:[NSNull class]]) {
                _scanType = scanType;
            }
        }
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _view = [[UIView alloc]initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, width, _viewHeight)];
        _view.backgroundColor = [UIColor whiteColor];

        UIImageView *lineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(toLeft, toTop, width - toLeft * 2, lineImageViewHeight)];
        lineImageView.tag = lineImageViewTag;
        lineImageView.image = [UIImage imageNamed:@"scan_line"];
        lineImageView.contentMode = UIViewContentModeScaleAspectFill;
        lineImageView.backgroundColor = [UIColor clearColor];
        [_view addSubview: lineImageView];

        NSMutableArray<NSString *> *metaDataObjectTypes = [NSMutableArray arrayWithArray:[self defaultMetaDataObjectTypes]];
        if (_scanType != nil && ![_scanType isKindOfClass:[NSNull class]]) {
            if ([_scanType intValue] == Barcode) {
                [metaDataObjectTypes removeObjectAtIndex:0];
            } else {
                metaDataObjectTypes = [NSMutableArray arrayWithObject:metaDataObjectTypes.firstObject];
            }
        }
        _scanner = [[MTBBarcodeScanner alloc]initWithMetadataObjectTypes:metaDataObjectTypes previewView:_view];
        [self startScanning];
    }
    return self;
}

- (NSArray<NSString *> *)defaultMetaDataObjectTypes {
    NSMutableArray *types = [@[AVMetadataObjectTypeQRCode,
                               AVMetadataObjectTypeUPCECode,
                               AVMetadataObjectTypeCode39Code,
                               AVMetadataObjectTypeCode39Mod43Code,
                               AVMetadataObjectTypeEAN13Code,
                               AVMetadataObjectTypeEAN8Code,
                               AVMetadataObjectTypeCode93Code,
                               AVMetadataObjectTypeCode128Code,
                               AVMetadataObjectTypePDF417Code,
                               AVMetadataObjectTypeAztecCode] mutableCopy];

    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
        [types addObjectsFromArray:@[AVMetadataObjectTypeInterleaved2of5Code,
                                     AVMetadataObjectTypeITF14Code,
                                     AVMetadataObjectTypeDataMatrixCode
                                     ]];
    }

    return [types copy];
}

- (void) addAnimation {
    UIView *lineView = [self.view viewWithTag:lineImageViewTag];
    lineView.hidden = NO;
    CABasicAnimation *animation = [FlutterBarcodeScannerView moveYTime:2 fromY:[NSNumber numberWithFloat:0] toY:[NSNumber numberWithFloat:(_viewHeight-toTop*2-lineImageViewHeight)] rep:OPEN_MAX];
    [lineView.layer addAnimation:animation forKey:@"LineAnimation"];
}

- (void) removeAnimation {
    UIView *lineView = [self.view viewWithTag:lineImageViewTag];
    [lineView.layer removeAnimationForKey:@"LineAnimation"];
    lineView.hidden = YES;
}

- (void) pauseScanning {
    [_scanner freezeCapture];
    [self removeAnimation];
}

- (void) resumeScanning {
    [_scanner unfreezeCapture];
    [self addAnimation];
}

- (void) stopScanning {
    if (self.scanner.isScanning) {
        [self removeAnimation];
    }
    [self.scanner stopScanning];
}

- (void) startScanning {
    if (self.scanner.isScanning) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [MTBBarcodeScanner requestCameraPermissionWithSuccess:^(BOOL success) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (success) {
            [strongSelf.scanner startScanningWithResultBlock:^(NSArray<AVMetadataMachineReadableCodeObject *> *codes) {
                if (strongSelf.delegate) {
                    AVMetadataMachineReadableCodeObject* object = [codes firstObject];
                    NSString * value = @"";
                    if (object != nil) {
                        value = object.stringValue;
                        if (object.type == AVMetadataObjectTypeEAN13Code && [value hasPrefix:@"0"]) {
                            value = [value substringFromIndex:1];
                        }
                    }
                    [strongSelf.delegate didScanBarcodeWithResult:value];
                }
            } error:nil];
            [strongSelf addAnimation];
        } else {
            [strongSelf.delegate cameraDenied:YES];
        }
    }];
}

+ (CABasicAnimation *)moveYTime:(float)time fromY:(NSNumber *)fromY toY:(NSNumber *)toY rep:(int)rep {
    CABasicAnimation *animationMove = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    [animationMove setFromValue:fromY];
    [animationMove setToValue:toY];
    animationMove.duration = time;
    animationMove.repeatCount  = rep;
    animationMove.fillMode = kCAFillModeForwards;
    animationMove.removedOnCompletion = NO;
    animationMove.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return animationMove;
}

- (nonnull UIView *)view {
    return _view;
}

- (void)dealloc {
    if (_scanner) {
        [_scanner stopScanning];
    }
    _scanner = nil;
    _view = nil;
}

@end
