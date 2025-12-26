//
//  RTCCaptureController.h
//  WuKongRTC
//
//  Created by tt on 2021/5/1.
//

#include <WebRTC/RTCCameraVideoCapturer.h>

NS_ASSUME_NONNULL_BEGIN

@interface RTCSettingsModel : NSObject

@property(nonatomic, assign) double frameRate;
@property(nonatomic, assign) CGSize resolution;

@end

@interface RTCCaptureController : NSObject
/** 视频采集者 */
@property (nonatomic, strong) RTCCameraVideoCapturer *capturer;

/// 初始化视频捕获管理者（默认使用前置摄像头）
/// @param capturer 视频捕获者
/// @param settings 视频设置属性
- (instancetype)initWithCapturer:(RTCCameraVideoCapturer *)capturer
                        settings:(RTCSettingsModel *)settings;

/// 开始捕获
- (void)startCaptureCompletionHandler:(void (^)(NSError * _Nullable error))completion;

- (void)stopCaptureWithCompletionHandler:(void (^)(void))completion;

/// 停止捕获
- (void)stopCapture;

/// 切换摄像头
- (void)switchCameraCompletionHandler:(void (^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
