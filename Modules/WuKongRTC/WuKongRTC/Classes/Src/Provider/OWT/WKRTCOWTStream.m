//
//  WKRTCOWTStream.m
//  WuKongRTC
//
//  Created by tt on 2022/9/17.
//

#import "WKRTCOWTStream.h"
#import <WebRTC/WebRTC.h>
@interface WKRTCOWTStream ()

@end

@implementation WKRTCOWTStream

- (instancetype)initStream:(id)stream uid:(NSString *)uid {
    self = [super initStream:stream uid:uid];
    if(self) {
    }
    return self;
}

- (void)stop {
    [super stop];
//    if([self.stream isKindOfClass:OWTRemoteStream.class]) {
//        ((OWTRemoteStream*)self.stream).delegate = nil;
//        self.stream = nil;
//    }
   
    if(self.publication) {
        [self.publication stop];
        self.publication = nil;
    }
    if(self.conferencePublication) {
        [self.conferencePublication stop];
        self.conferencePublication = nil;
    }
    if(self.subscription) {
        [self.subscription stop];
        self.subscription = nil;
    }
    if(self.participant) {
        self.participant = nil;
    }
}

- (void)setDelegate:(id<WKRTCOWTStreamDelegate>)delegate {
    _delegate = delegate;
    if([self.stream isKindOfClass:OWTRemoteStream.class]) {
            ((OWTRemoteStream*)self.stream).delegate = _delegate;
    }
    if(self.subscription) {
        self.subscription.delegate = _delegate;
    }
    if(self.publication) {
        self.publication.delegate = _delegate;
    }
    if(self.conferencePublication) {
        self.conferencePublication.delegate = _delegate;
    }
    if(self.participant) {
        self.participant.delegate = _delegate;
    }
}

- (void)setSubscription:(OWTConferenceSubscription *)subscription {
    _subscription = subscription;
    if(subscription && self.delegate) {
        subscription.delegate = self.delegate;
    }
}

- (void)setPublication:(OWTP2PPublication *)publication {
    _publication = publication;
    if(publication && self.delegate) {
        publication.delegate =  self.delegate;
    }
}

- (void)setParticipant:(OWTConferenceParticipant *)participant {
    _participant = participant;
    if(participant && self.delegate) {
        participant.delegate =  self.delegate;
    }
}

- (void)setMute:(BOOL)mute {
    [super setMute:mute];
    
    if([self.stream isKindOfClass:[OWTStream class]]) {
        [((OWTStream*)self.stream).mediaStream.audioTracks.firstObject setIsEnabled:!mute];
    }
}

- (BOOL)mute {
   BOOL mt = [super mute];
    if(mt) {
        return mt;
    }
    
    if([self.stream isKindOfClass:[OWTStream class]]) {
        return ((OWTStream*)self.stream).mediaStream.audioTracks.firstObject.isEnabled;
    }
    return false;
}

- (void)setOpenVideo:(BOOL)openVideo {
    [super setOpenVideo:openVideo];
    
    if(self.conferencePublication) {
        if(openVideo) {
            [self.conferencePublication unmute:OWTTrackKindVideo onSuccess:^{
                
            } onFailure:^(NSError * err) {
                NSLog(@"打开视频失败！-->%@",err);
            }];
        }else {
            [self.conferencePublication mute:OWTTrackKindVideo onSuccess:^{
                
            } onFailure:^(NSError * err) {
                NSLog(@"关闭视频失败！-->%@",err);
            }];
        }
       
    }
}

- (void)dealloc {
    NSLog(@"WKRTCOWTStream dealloc -->%@",self.uid);
}


@end
