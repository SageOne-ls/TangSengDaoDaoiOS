//
//  WKAudioSessionManager.m
//  WuKongRTC
//
//  Created by tt on 2022/9/23.
//

#import "WKAudioSessionManager.h"

#import <WebRTC/WebRTC.h>
@interface WKAudioSessionManager ()

/**
 *  用来存储所有添加j过的delegate
 *  NSHashTable 与 NSMutableSet相似，但NSHashTable可以持有元素的弱引用，而且在对象被销毁后能正确地将其移除。
 */
@property (strong, nonatomic) NSHashTable  *delegates;
/**
 *  delegateLock 用于给delegate的操作加锁，防止多线程同时调用
 */
@property (strong, nonatomic) NSLock  *delegateLock;

@end

@implementation WKAudioSessionManager


static WKAudioSessionManager *_instance;


+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKAudioSessionManager *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        [_instance setup];
    });
    return _instance;
}

-(void) setup{
    AVAudioSessionRouteDescription *currentRoute = AVAudioSession.sharedInstance.currentRoute;
    if(self.availablePorts.count==1) {
        BOOL isSpeaker = [currentRoute.outputs.firstObject.portType isEqualToString:@"Speaker"];
        self.suggetAudioSessionPortOverride = isSpeaker?AVAudioSessionPortOverrideNone:AVAudioSessionPortOverrideSpeaker;
    }else {
        self.suggetAudioSessionPortOverride = AVAudioSessionPortOverrideNone;
        self.suggetAudioSessionPortDescription = self.availablePorts.firstObject;
    }
    
    // 监听耳机状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)setIsSpeaker:(BOOL)isSpeaker {
    _isSpeaker = isSpeaker;
    
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    if (isSpeaker) {
        [RTCAudioSession.sharedInstance lockForConfiguration];
        [RTCAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        [RTCAudioSession.sharedInstance unlockForConfiguration];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    } else {
        [RTCAudioSession.sharedInstance lockForConfiguration];
        [RTCAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
        [RTCAudioSession.sharedInstance unlockForConfiguration];
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord  error:nil];
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    }
}


- (void)routeChange:(NSNotification *)notify {
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    AVAudioSessionPortDescription *newPort = route.inputs.firstObject; // 新设备
    if(!newPort) {
        return;
    }
    BOOL isExist = false;
    for (AVAudioSessionPortDescription *des in self.availablePorts) {
        if ([des.portType isEqualToString:newPort.portType] && [des.portName isEqualToString:newPort.portName]) {
            isExist = true;
            break;
        }
    }
    if (!isExist) {
        [self.availablePorts insertObject:newPort atIndex:0];
    }
    if([AVAudioSession.sharedInstance.currentRoute.outputs.firstObject.portType isEqualToString:@"Receiver"]) {
        if (AVAudioSession.sharedInstance.availableInputs.count == 1) { // 没有外设
            self.suggetAudioSessionPortOverride = AVAudioSessionPortOverrideSpeaker;
        }else {// 有外设
            self.suggetAudioSessionPortOverride = AVAudioSessionPortOverrideNone;
            self.suggetAudioSessionPortDescription = self.availablePorts.firstObject;
           
        }
    }
    [self callAudioSessionManagerDidRouteChange];
}

- (NSMutableArray<AVAudioSessionPortDescription *> *)availablePorts {
    if (_availablePorts == nil) {
        _availablePorts = [[[AVAudioSession sharedInstance] availableInputs] mutableCopy];
    }
    if(_availablePorts == nil) {
        _availablePorts = [NSMutableArray array];
    }
    return _availablePorts;
}
- (NSLock *)delegateLock {
    if (_delegateLock == nil) {
        _delegateLock = [[NSLock alloc] init];
    }
    return _delegateLock;
}

-(NSHashTable*) delegates {
    if (_delegates == nil) {
        _delegates = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _delegates;
}



-(void) addDelegate:(id<WKAudioSessionManagerDelegate>) delegate{
    [self.delegateLock lock];//防止多线程同时调用
    [self.delegates addObject:delegate];
    [self.delegateLock unlock];
}
- (void)removeDelegate:(id<WKAudioSessionManagerDelegate>) delegate {
    [self.delegateLock lock];//防止多线程同时调用
    [self.delegates removeObject:delegate];
    [self.delegateLock unlock];
}

-(void) callAudioSessionManagerDidRouteChange {
    [self.delegateLock lock];
    NSHashTable *copyDelegates =  [self.delegates copy];
    [self.delegateLock unlock];
    for (id delegate in copyDelegates) {//遍历delegates ，call delegate
        if(!delegate) {
            continue;
        }
        if ([delegate respondsToSelector:@selector(audioSessionManagerDidRouteChange:)]) {
            if (![NSThread isMainThread]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate audioSessionManagerDidRouteChange:self];
                });
            }else {
                [delegate audioSessionManagerDidRouteChange:self];
            }
        }
    }
}


@end
