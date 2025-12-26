//
//  WKCaptureController.m
//  WuKongRTC
//
//  Created by tt on 2021/5/1.
//

#import "WKCaptureController.h"
#import <WebRTC/WebRTC.h>
#import <Foundation/Foundation.h>
#import "RTCCaptureController.h"
#import <OWT/RTCPeerConnectionFactory+OWT.h>

@interface WKCaptureController ()


@property (nonatomic, strong) RTCCaptureController *captureController;

@property(nonatomic,strong) RTCPeerConnectionFactory *factory;

@property(nonatomic,strong) RTCAudioTrack *audioTrack;
@property(nonatomic,strong) RTCVideoTrack *videoTrack;

@end

@implementation WKCaptureController

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (AVCaptureSession *)captureSession {
    return self.captureController.capturer.captureSession;
}

- (RTCPeerConnectionFactory *)factory {
    if(!_factory) {
        _factory = [RTCPeerConnectionFactory sharedInstance];
    }
    return _factory;
}

-(void) setupLocalStream {
    
    NSString *uuidstr = [[[NSUUID UUID] UUIDString]
                            stringByReplacingOccurrencesOfString:@"-"
                            withString:@""];
    RTCVideoSource *source = [self.factory videoSource];
    //创建本地流
    RTCMediaStream *mediaStream = [self.factory mediaStreamWithStreamId:uuidstr];
    [self addAudioTrack:mediaStream];
#if TARGET_IPHONE_SIMULATOR

#else
    [self addVideoTrack:mediaStream source:source];
#endif

    //设置音视频捕获源
    OWTStreamSourceInfo *sInfo = [[OWTStreamSourceInfo alloc]init];
    sInfo.audio = OWTAudioSourceInfoMic;
    sInfo.video = OWTVideoSourceInfoCamera;
    [mediaStream.videoTracks firstObject].isEnabled = false;
    self.localStream = [[OWTLocalStream alloc] initWithMediaStream:mediaStream source:sInfo];

    [self setupCaptureController:source];
    
//    if(!self.localStream) {
//        OWTStreamConstraints* constraints=[[OWTStreamConstraints alloc] init];
//        constraints.audio=YES;
//        constraints.video=[[OWTVideoTrackConstraints alloc] init];
//        constraints.video.frameRate=24;
//        constraints.video.resolution=CGSizeMake(640,480);
//        constraints.video.devicePosition=AVCaptureDevicePositionFront;
//        dispatch_async(dispatch_get_main_queue(), ^{
//          self.localStream=[[OWTLocalStream alloc] initWithConstratins:constraints error:nil];
//        });
//    }
    
}

- (void)dismiss {
    [self.captureController stopCapture];
    self.audioTrack.isEnabled =false;
    self.videoTrack.isEnabled = false;
    if(self.localStream.mediaStream) {
        [self.localStream.mediaStream removeAudioTrack:self.audioTrack];
        [self.localStream.mediaStream removeVideoTrack:self.videoTrack];
    }
}

-(void) addAudioTrack:(RTCMediaStream *)mediaStream{
    NSString *uuidstr = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    //音频
    self.audioTrack = [self.factory audioTrackWithTrackId:uuidstr];
    //将audioTrack、videoTrack添加到流
    [mediaStream addAudioTrack:self.audioTrack];
}

- (void)addVideoTrack:(RTCMediaStream *)mediaStream source:(RTCVideoSource*)source{
    NSString *uuidstr = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    self.videoTrack = [self.factory videoTrackWithSource:source trackId:uuidstr];
    [mediaStream addVideoTrack:self.videoTrack];
    self.videoTrack.isEnabled = false;
}

- (void)openVideo:(BOOL)on {
    self.localStream.mediaStream.videoTracks.firstObject.isEnabled = on;
    if(on) {
        [self startCaptureCompletionHandler:nil];
    }else {
        [self.captureController stopCapture];
    }
}

-(BOOL) isOpenVideo {
    return self.localStream.mediaStream.videoTracks.firstObject.isEnabled;
}

- (void)openVoice:(BOOL)on {
    self.localStream.mediaStream.audioTracks.firstObject.isEnabled = on;
}

- (void)switchCamera {
    [self.captureController switchCameraCompletionHandler:nil];
}

-(void) setupCaptureController:(RTCVideoSource*)source {
    //拿到capture对象
    RTCCameraVideoCapturer *capturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:source];
    //视频捕获管理者
    RTCSettingsModel *settings = [[RTCSettingsModel alloc] init];
    settings.frameRate = 20;
    
    settings.resolution = CGSizeMake(640, 480); // 640x480,960 x 540,
    
    self.captureController = [[RTCCaptureController alloc] initWithCapturer:capturer
                                                                  settings:settings];
    capturer.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = false;
   
}

-(void) stopCapture {
    [self.captureController stopCapture];
}

-(void) stopCaptureWithCompletionHandler:(nullable void (^)(void))completionHandler {
    [self.captureController stopCaptureWithCompletionHandler:completionHandler];
}


- (void)startCaptureCompletionHandler:(void (^)(NSError * error))completion {
    [self.captureController startCaptureCompletionHandler:^(NSError * _Nullable error) {
           dispatch_async(dispatch_get_main_queue(), ^{
               if(completion) {
                   completion(error);
               }
              // capturer.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = false;
   //            selfWeak.delegate.localVideoView.localVideoView.captureSession = capturer.captureSession;
           });
       }];
}

- (void)dealloc
{
    NSLog(@"WKCaptureController dealloc");
}

@end
