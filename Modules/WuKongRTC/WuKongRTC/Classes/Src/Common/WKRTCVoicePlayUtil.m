//
//  WKRTCVoicePlayUtil.m
//  WuKongRTC
//
//  Created by tt on 2021/5/7.
//

#import "WKRTCVoicePlayUtil.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <WebRTC/WebRTC.h>
#import "WKApp.h"
@interface WKRTCVoicePlayUtil ()

@property(nonatomic,strong) AVAudioPlayer  *player;

@end

@implementation WKRTCVoicePlayUtil


static WKRTCVoicePlayUtil *_instance;


+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCVoicePlayUtil *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
       
    }
    return self;
}

- (void)call {
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self stopShock];
    if (self.player && self.player.isPlaying) {
        return;
    }
    [self playSourceName:@"call.aac" numberOfLoops:20];
}

- (void)receive {
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self stopShock];
    if (self.player && self.player.isPlaying) {
        return;
    }
    [self shock];
    [self playSourceName:@"receive.caf" numberOfLoops:20];
}

-(void) stopAll {
    if (self.player && self.player.isPlaying) {
        [self.player stop];
    }
    [self stopShock];
//    [self setIsAudioEnabled:YES];
}

- (void)playSourceName:(NSString *)source numberOfLoops:(NSInteger)numberOfLoops {
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:nil];
    NSBundle *moduleBundle = [WKApp.shared resourceBundle:@"WuKongRTC"];
    NSString* path = [moduleBundle pathForResource:[NSString stringWithFormat:@"Others/%@",source]
                                    ofType:nil];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:path] error:nil];
    self.player.numberOfLoops = numberOfLoops;
    [self.player play];
}

- (void)shock {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    [self performSelector:@selector(shock) withObject:nil afterDelay:1];
}
//停止响铃及振动

-(void)stopShock{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shock) object:nil];
}

@end
