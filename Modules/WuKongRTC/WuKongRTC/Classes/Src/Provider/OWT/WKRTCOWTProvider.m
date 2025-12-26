//
//  WKRTCOWTProvider.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCOWTProvider.h"
#import "WKRTCOWTClientImpl.h"
#import <OWT/OWT.h>
#import <WebRTC/WebRTC.h>
#import "WKRTCManager.h"
#import "WKRTCOWTStream.h"
#import "WKCaptureController.h"

@interface WKRTCOWTProvider ()

@property(nonatomic,strong) WKCaptureController *captureController;

@property(nonatomic,assign) BOOL isCapturing;


@end

@implementation WKRTCOWTProvider

- (id<WKRTCClientProtocol>)getClient:(WKRTCMode)mode {
    if(mode == WKRTCModeConference) {
        return [WKRTCOWTConferenceClientImpl shared];
    }
    return [WKRTCOWTP2PClientImpl shared];
}

-(WKRTCStream*) getLocalStream {
    RTCPeerConnectionFactory *factory = [RTCPeerConnectionFactory sharedInstance];
    NSString *uuidstr = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    //创建本地流
    RTCMediaStream *mediaStream = [factory mediaStreamWithStreamId:uuidstr];
    //音频
    RTCAudioTrack * audioTrack = [factory audioTrackWithTrackId:uuidstr];
    
    [mediaStream addAudioTrack:audioTrack];
    [self addVideoTrack:mediaStream];
    
    if(WKRTCManager.shared.currentChannel.channelType == WK_GROUP) {
        OWTStreamSourceInfo *sInfo = [[OWTStreamSourceInfo alloc]init];
        sInfo.audio = OWTAudioSourceInfoMic;
        sInfo.video = OWTVideoSourceInfoCamera;
        [mediaStream.audioTracks.firstObject setIsEnabled:YES];
        OWTLocalStream *localStream = [[OWTLocalStream alloc] initWithMediaStream:mediaStream source:sInfo];
        [localStream setAttributes:@{@"from":WKRTCManager.shared.options.uid?:@""}];
        return [[WKRTCOWTStream alloc] initStream:localStream uid:WKRTCManager.shared.options.uid];
    }
    WKRTCOWTStream *rtcStream = [[WKRTCOWTStream alloc] initStream:mediaStream uid:WKRTCManager.shared.options.uid];
    return rtcStream;
}
- (void)addVideoTrack:(RTCMediaStream*)stream {
    RTCPeerConnectionFactory *factory = [RTCPeerConnectionFactory sharedInstance];
    NSString *uuidstr = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    //获取数据源
    RTCVideoSource *source = [factory videoSource];
    RTCVideoTrack *videoTrack = [factory videoTrackWithSource:source trackId:uuidstr];
    videoTrack.isEnabled = false;
    [stream addVideoTrack:videoTrack];
}


-(void) startCaptureCompletionHandler:(RTCVideoSource*)source complete:(void(^)(void))complete{
    if(!self.captureController) {
        self.captureController = [[WKCaptureController alloc] init];
        [self.captureController setupCaptureController:source];
        if(!self.isCapturing) {
            self.isCapturing = true;
            NSLog(@"startCaptureCompletionHandler--->startCaptureCompletionHandler");
            [self.captureController startCaptureCompletionHandler:^(NSError * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(complete) {
                        complete();
                    }
                });
            }];
        }
    }
}

-(void) streamRender:(id)stream target:(id)targetView {
    if([stream isKindOfClass:RTCMediaStream.class]) {
        RTCMediaStream *mediaStream = (RTCMediaStream*)stream;
        if([targetView isKindOfClass:RTCCameraPreviewView.class]) {
            NSLog(@"streamRender--------------->RTCMediaStream");
            RTCVideoSource *source = mediaStream.videoTracks.firstObject.source;
            RTCCameraPreviewView *cameraPreviewView = (RTCCameraPreviewView*)targetView;
            __weak typeof(self) weakSelf = self;
            [self startCaptureCompletionHandler:source complete:^{
                cameraPreviewView.captureSession = weakSelf.captureController.captureSession;
            }];
        }else {
            [mediaStream.videoTracks.firstObject addRenderer:targetView];
        }
    }else if([stream isKindOfClass:OWTLocalStream.class]) {
        NSLog(@"streamRender--------------->OWTLocalStream");
        OWTLocalStream *localStream = (OWTLocalStream*)stream;
        RTCVideoSource *source = localStream.mediaStream.videoTracks.firstObject.source;
        [self startCaptureCompletionHandler:source complete:^{

        }];
        [localStream.mediaStream.videoTracks.firstObject addRenderer:targetView];
        
    }else if([stream isKindOfClass:OWTStream.class]) {
        OWTStream *owtStream = (OWTStream*)stream;
        [owtStream.mediaStream.videoTracks.firstObject addRenderer:targetView];
    }
//   OWTStream *owtStream = (OWTStream*)stream;
////    [owtStream.mediaStream.videoTracks.lastObject addRenderer:target];
//    [owtStream attach:(NSObject<RTCVideoRenderer>*)target];
}

-(void) streamUnrender:(id)stream target:(id)targetView {
   
    if([stream isKindOfClass:RTCMediaStream.class]) {
        RTCMediaStream *mediaStream = (RTCMediaStream*)stream;
        if([targetView isKindOfClass:RTCCameraPreviewView.class]) {
            if(self.captureController) {
                NSLog(@"streamUnrender--------->RTCMediaStream");
                [self.captureController.captureSession stopRunning];
                [self.captureController stopCapture];
                self.isCapturing = false;
                
                self.captureController = nil;
            }
        }else{
            [mediaStream.videoTracks.firstObject removeRenderer:targetView];
            mediaStream.videoTracks.firstObject.isEnabled = false;
            mediaStream.audioTracks.firstObject.isEnabled = false;
        }
        
    }else if([stream isKindOfClass:OWTLocalStream.class]) {
        OWTLocalStream *localStream = (OWTLocalStream*)stream;
        if(self.captureController) {
            [self.captureController.captureSession stopRunning];
            [self.captureController stopCapture];
            self.isCapturing = false;
            self.captureController = nil;
        }
        [localStream.mediaStream.videoTracks.firstObject removeRenderer:targetView];
    }else if([stream isKindOfClass:OWTStream.class]) {
        OWTStream *owtStream = (OWTStream*)stream;
        [owtStream.mediaStream.videoTracks.firstObject removeRenderer:targetView];
    }
}

-(BOOL) isOpenVideo:(id)stream {
    RTCMediaStream *mediaStream;
    if([stream isKindOfClass:[RTCMediaStream class]]) {
        mediaStream = (RTCMediaStream*)stream;
    }else if([stream isKindOfClass:[OWTLocalStream class]]){
        mediaStream = ((OWTLocalStream*)stream).mediaStream;
    }else if([stream isKindOfClass:[OWTRemoteStream class]]) {
        mediaStream = ((OWTRemoteStream*)stream).mediaStream;
    }
    if(mediaStream) {
        return mediaStream.videoTracks.firstObject.isEnabled;
    }
    return false;
}

- (void)openVoice:(BOOL)on stream:(id)stream{
    if([stream isKindOfClass:[RTCMediaStream class]]) {
        RTCMediaStream *mediaStream = (RTCMediaStream*)stream;
        mediaStream.audioTracks.firstObject.isEnabled = on;
    }
}

-(void) openVideo:(BOOL)openVideo stream:(id)stream{
    
    RTCMediaStream *mediaStream;
    if([stream isKindOfClass:[RTCMediaStream class]]) {
        mediaStream = (RTCMediaStream*)stream;
    }else if([stream isKindOfClass:[OWTLocalStream class]]){
        mediaStream = ((OWTLocalStream*)stream).mediaStream;
    }else if([stream isKindOfClass:[OWTRemoteStream class]]){
        mediaStream = ((OWTRemoteStream*)stream).mediaStream;
    }
    
    if(mediaStream) {
        mediaStream.videoTracks.firstObject.isEnabled = openVideo;
    }
}

-(void) switchCamera {
    if(self.captureController) {
        [self.captureController switchCamera];
    }
}





@end
