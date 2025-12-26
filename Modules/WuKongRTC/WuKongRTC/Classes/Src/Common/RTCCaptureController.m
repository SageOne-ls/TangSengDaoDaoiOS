//
//  RTCCaptureController.m
//  WuKongRTC
//
//  Created by tt on 2021/5/1.
//

#import "RTCCaptureController.h"

@implementation RTCSettingsModel

@end

@interface RTCCaptureController ()

/** 是否使用前置摄像头 */
@property (nonatomic, assign) BOOL usingFrontCamera;
/** 采集属性 */
@property (nonatomic, strong) RTCSettingsModel *settings;

@end

@implementation RTCCaptureController

- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                        settings:(RTCSettingsModel *)settings {
    if ([super init]) {
      _capturer = capturer;
      _settings = settings;
      _usingFrontCamera = YES;
    }
    return self;
}

- (void)startCaptureCompletionHandler:(void (^)(NSError * _Nullable error))completion {

    AVCaptureDevicePosition position =
    _usingFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
    AVCaptureDevice *device = [self findDeviceForPosition:position];
    AVCaptureDeviceFormat *format = [self selectFormatForDevice:device];
    NSInteger fps = _settings.frameRate ? _settings.frameRate : 20;
    [_capturer startCaptureWithDevice:device format:format fps:fps completionHandler:^(NSError * _Nonnull error) {
        if (completion) {
            completion(error);
        }
    }];
}

- (void)stopCapture {
    [_capturer stopCapture];
    
}
- (void)stopCaptureWithCompletionHandler:(void (^)(void))completion {
    [_capturer stopCaptureWithCompletionHandler:completion];
    
}

- (void)switchCameraCompletionHandler:(void (^)(NSError * _Nullable error))completion {
    _usingFrontCamera = !_usingFrontCamera;
    [self startCaptureCompletionHandler:completion];
}

#pragma mark - Private

- (AVCaptureDevice *)findDeviceForPosition:(AVCaptureDevicePosition)position {
    NSArray<AVCaptureDevice *> *captureDevices = [RTCCameraVideoCapturer captureDevices];
    for (AVCaptureDevice *device in captureDevices) {
        if (device.position == position) {
            return device;
        }
    }
    return captureDevices[0];
}

- (AVCaptureDeviceFormat *)selectFormatForDevice:(AVCaptureDevice *)device {
    NSArray<AVCaptureDeviceFormat *> *formats = [RTCCameraVideoCapturer supportedFormatsForDevice:device];
    AVCaptureDeviceFormat *selectedFormat = nil;
    
    if (_settings.resolution.width == 0 &&
        _settings.resolution.height == 0) {
      selectedFormat = formats[0];
    } else {
      for (AVCaptureDeviceFormat* format in formats) {
        CMVideoDimensions dimension =
            CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        if (dimension.width == _settings.resolution.width &&
            dimension.height == _settings.resolution.height) {
          for (AVFrameRateRange* frameRateRange in
               [format videoSupportedFrameRateRanges]) {
            if (frameRateRange.minFrameRate <= _settings.frameRate &&
                _settings.frameRate <= frameRateRange.maxFrameRate) {
              selectedFormat = format;
              break;
            }
          }
        }
        if(selectedFormat){
          break;
        }
      }
    }
    
    NSAssert(selectedFormat != nil, @"No suitable capture format found.");
    return selectedFormat;
}

@end
