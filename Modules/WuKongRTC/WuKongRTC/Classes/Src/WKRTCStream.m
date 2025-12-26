//
//  WKRTCStream.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCStream.h"
#import "WKRTCManager.h"
#import <WebRTC/WebRTC.h>
@interface WKRTCStream ()

@property(nonatomic,strong,nullable) NSObject *render;

@end

@implementation WKRTCStream

-(instancetype) initStream:(id)stream uid:(NSString*)uid {
    self = [super init];
    if(self) {
        self.stream = stream;
        self.uid = uid;
    }
    return self;
}

- (void)attach:(NSObject*)renderer {
    self.render = renderer;
    if(self.stream) {
        [WKRTCManager.shared.options.provider streamRender:self.stream target:renderer];
    }
}

-(void) unattach {
    if(self.stream) {
        [WKRTCManager.shared.options.provider streamUnrender:self.stream target:self.render];
        self.stream = nil;
    }
}

-(void) switchCamera {
    [WKRTCManager.shared.options.provider switchCamera];
}

- (void)setOpenVideo:(BOOL)openVideo {
    [WKRTCManager.shared.options.provider openVideo:openVideo stream:self.stream];
}

- (BOOL)openVideo {
    if(!self.stream) {
        return false;
    }
    return [WKRTCManager.shared.options.provider isOpenVideo:self.stream];
}

- (void)setMute:(BOOL)mute {
    if([self.stream isKindOfClass:[RTCMediaStream class]]) {
        RTCMediaStream *mediaStream = (RTCMediaStream*)self.stream;
        mediaStream.audioTracks.firstObject.isEnabled = !mute;
    }
}

- (BOOL)mute {
    if([self.stream isKindOfClass:[RTCMediaStream class]]) {
        RTCMediaStream *mediaStream = (RTCMediaStream*)self.stream;
        return mediaStream.audioTracks.firstObject.isEnabled;
    }
    return false;
}

- (void)setHandsFree:(BOOL)handsFree {
    _handsFree = handsFree;
    
}


- (void)setAudioOutputPort:(AVAudioSessionPortOverride)type {
    if (type == AVAudioSessionPortOverrideNone) {
        [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    }
    else {
        [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
}


-(void) stop {
    [self unattach];
}

@end
