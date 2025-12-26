//
//  WKCaptureController.h
//  WuKongRTC
//
//  Created by tt on 2021/5/1.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <OWT/OWT.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKCaptureController : NSObject

@property(readonly, nonatomic) AVCaptureSession *captureSession;

@property(nonatomic, strong) OWTLocalStream *localStream;

- (void)startCaptureCompletionHandler:(void (^__nullable)(NSError * _Nullable error))completion;

// 初始化本地视频流
-(void) setupLocalStream;

-(void) dismiss;

-(void) openVideo:(BOOL)on; // 打开视频

-(BOOL) isOpenVideo; // 是否打开视频
 
-(void) openVoice:(BOOL)on; // 打开声音

/**
 切换摄像头
 */
- (void)switchCamera;

-(void) setupCaptureController:(RTCVideoSource*)source ;

-(void) stopCapture;

-(void) stopCaptureWithCompletionHandler:(nullable void (^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
