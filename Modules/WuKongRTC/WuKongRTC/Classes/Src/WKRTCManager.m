//
//  WKRTCManager.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCManager.h"

#import "WKRTCClientManager.h"
#import "WKRTCStreamManager.h"
#import "WKRTCUIManager.h"
#import "WKRTCP2PSignalingManager.h"
#import "WKRTCConstants.h"
#import "WKRTCConferenceClientProtocol.h"
#import "WKRTCAPIClient.h"
#import "WKRTCRoomUtil.h"
#import "WKVideoCallSystemContent.h"
#import <WuKongBase/WuKongBase.h>
#import "WKAudioSessionManager.h"
#import "WKRTCVoicePlayUtil.h"
#import "WKApp.h"
#import "WKP2PChatView.h"
#import "WKAvatarUtil.h"
@interface WKRTCManager ()<WKRTCStreamManagerDelegate,WKChatManagerDelegate,WKCMDManagerDelegate,WKAudioSessionManagerDelegate,WKRTCClientProtocolDelegate>



@property(nonatomic,assign) BOOL localStreamPublished;

@property(nonatomic,assign) BOOL isSpeaker; // 是否扬声器播放

@property(nonatomic,strong) NSMutableDictionary<NSString*,WKRTCParticipant*> *participantCacheDict; // 参与者缓存

@property(nonatomic,strong) NSString *caller; // 发起者uid

@property(nonatomic,assign) BOOL isTalking; // 是否正在通话

@property(nonatomic,assign) BOOL switchVideoAlertShow; // 切换视频弹出请求是否显示


@property(nonatomic,copy,nullable) NSString *currentRoomID; // 当前房间ID



@end

@implementation WKRTCManager


static WKRTCManager *_instance;


+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCManager *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        [_instance setup];
    });
    return _instance;
}
- (NSMutableDictionary *)participantCacheDict {
    if(!_participantCacheDict) {
        _participantCacheDict = [NSMutableDictionary dictionary];
    }
    return _participantCacheDict;
}

-(void) setup {
    NSError *err;
    [RTCAudioSession.sharedInstance lockForConfiguration];
    [RTCAudioSession.sharedInstance setPreferredSampleRate:8000 error:&err];
    [RTCAudioSession.sharedInstance setPreferredOutputNumberOfChannels:1 error:&err];
    [RTCAudioSession.sharedInstance setInputGain:0.01 error:&err];                                //输入增益
    RTCAudioSession.sharedInstance.useManualAudio = YES; // 手动控制音频 通过 setIsAudioEnabled
    [RTCAudioSession.sharedInstance unlockForConfiguration];
    
    
    
    [WKRTCStreamManager.shared setDelegate:self];
    [WKSDK.shared.cmdManager addDelegate:self];
    
    [WKSDK.shared.chatManager addDelegate:self];
    
//    [WKAudioSessionManager.shared addDelegate:self]; // 音频外设监听
    
    [WKRTCClientManager.shared setDelegate:self];
    
    
   
}



-(void) initCall {
    
    if(self.currentChannel.channelType == WK_PERSON && self.callType == WKRTCCallTypeAudio) {
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES]; //这个功能是开启红外感应
    }
   

    
    [self addDelegates];
//    [self setOutputAudio];
    
   
}

-(void) setOutputAudio {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:WKAudioSessionManager.shared.suggetAudioSessionPortOverride error:nil];
    if(WKAudioSessionManager.shared.suggetAudioSessionPortDescription) {
        [AVAudioSession.sharedInstance setPreferredInput:WKAudioSessionManager.shared.suggetAudioSessionPortDescription error:nil];
    }
}

-(void) addDelegates {
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

-(void) removeDelegates {
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];

}

- (void (^)(NSString * uid, ParticipantCallback _Nonnull))getParticipant {
    __weak typeof(self) weakSelf = self;
    return ^(NSString * uid, ParticipantCallback callback){
       WKRTCParticipant *participant =  weakSelf.participantCacheDict[uid];
        if(participant) {
            callback(participant);
            return;
        }
        WKRTCManager.shared.options.getParticipant(uid, ^(WKRTCParticipant *p){
            if(uid) {
                weakSelf.participantCacheDict[uid] = p;
                callback(p);
            }else {
                NSLog(@"uid is empty");
            }
          
        });
    };
}
- (void)roteChange:(NSNotification *)noti {
    lim_dispatch_main_async_safe(^{
        if (![self isHeadPhoneEnable]) {//没有耳机根据当前状态切换
            if (self.isSpeaker) {
                [self switchAudioCategaryWithSpeaker:YES];
            } else {
               [self switchAudioCategaryWithSpeaker:NO];
            }
        } else {//有耳机走听筒
           [self switchAudioCategaryWithSpeaker:NO];
        }
    });
}


- (BOOL)isHeadPhoneEnable {//判断是否插入耳机
    AVAudioSessionRouteDescription *route = [[AVAudioSession sharedInstance] currentRoute];
    BOOL isHeadPhoneEnable = NO;
    for (AVAudioSessionPortDescription *desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            isHeadPhoneEnable = YES;
        }
    }
    return isHeadPhoneEnable;
}

//扬声器和听筒的切换
- (void)switchAudioCategaryWithSpeaker:(BOOL)isSpeaker {
    WKAudioSessionManager.shared.isSpeaker = isSpeaker;
}

- (WKRTCOption *)options {
    if(!_options) {
        _options = [[WKRTCOption alloc] init];
    }
    return _options;
}
- (void)call:(WKChannel *)channel callType:(WKRTCCallType)callType {
    self.isSpeaker = true;
    self.callType = callType;
    self.currentChannel = channel;
    [self initCall];
    WKRTCMode mode = WKRTCModeP2P;
    if(channel.channelType == WK_GROUP) {
        mode = WKRTCModeConference;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [self.delegate rtcManager:self didInviteAtChannel:channel data:nil complete:^(NSArray<NSString *> * _Nonnull participants) {
        if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(dispatch_get_main_queue())) {
            [weakSelf startCall:channel participants:participants mode:mode];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf startCall:channel participants:participants mode:mode];
            });
        }
       
    }];
}


-(void) startCall:(WKChannel*)channel participants:(NSArray<NSString *>*)participants mode:(WKRTCMode)mode{
    if(!participants||participants.count == 0) {
        return;
    }
    self.currentChannel = channel;
    self.isCallCreater = true;
    self.isTalking = true;
    
   id<WKRTCClientProtocol> client = [WKRTCClientManager.shared getClient:mode];
    [client setReceiveMessage:true];
    
    [WKRTCVoicePlayUtil.shared call];
    
    
    __weak typeof(self) weakSelf = self;

    
    NSMutableArray<WKRTCParticipant*> *newParticipantModels = [NSMutableArray array];
    WKRTCParticipant *creater = [[WKRTCParticipant alloc] initWithUID:WKApp.shared.loginInfo.uid];
    creater.role = WKRTCParticipantRoleInviter;
    creater.avatar = [NSURL URLWithString:[WKAvatarUtil getAvatar:WKApp.shared.loginInfo.uid]];
    [newParticipantModels addObject:creater];
    for (NSString *participantID in participants) {
        if([participantID isEqualToString:WKApp.shared.loginInfo.uid]) {
            continue;
        }
        WKRTCParticipant *p = [[WKRTCParticipant alloc] initWithUID:participantID];
        p.avatar = [NSURL URLWithString: [WKAvatarUtil getAvatar:participantID]];
        [newParticipantModels addObject:p];
    }
    
    // 创建rtc视图
    self.caller = WKRTCManager.shared.options.uid;
    if(channel.channelType == WK_PERSON) {
       
        self.rtcChatView = [self createP2PChatView:WKRTCViewTypeCall participants:newParticipantModels];
    }else{
       
        self.rtcChatView = [self createConferenceChatView:WKRTCViewTypeCall participants:newParticipantModels];
    }
    [self.rtcChatView setOnHangup:^{ // 如果createRoom之前按挂断 只执行endRTC
        [weakSelf endRTC];
    }];
//    // 获取客户端
//   id<WKRTCClientProtocol> client = [[WKRTCClientManager shared] getClient:mode];
//    // 本地stream
    
    // 推流
//    [client publishStream:localStream mode:mode];
    
    // 显示UI
    [self showView: (UIView*)self.rtcChatView animation:YES];
//    // 渲染本地流到View
    [self renderLocalStreamToView];
//
    // 创建房间
    [WKRTCStreamManager.shared createRoom:channel participants:newParticipantModels callType:self.callType complete:^(NSString * _Nonnull roomID,NSString *token, NSError * _Nonnull error) {
        if(error) {
            NSLog(@"创建房间失败！->%@",error);
            [(UIView*)weakSelf.rtcChatView showHUDWithHide:@"创建房间失败！"];
            [weakSelf endRTC];
            return;
        }
        [weakSelf subscribeRoom:roomID token:token publishStream:channel.channelType != WK_PERSON];
        
        [weakSelf.rtcChatView setOnHangup:^{
            lim_dispatch_main_async_safe(^{
                [weakSelf handleHangup:roomID];
            });
            
        }];
    }];
}

// 参与者离开
-(void) participantLeave:(NSString*)uid reason:(NSString* __nullable)reason{
    if(self.rtcChatView) {
        [self.rtcChatView leave:uid reason:reason];
    }
}


-(void) renderLocalStreamToView {
    
    WKRTCStreamView *localView = [self.rtcChatView streamView:self.options.uid];
    WKRTCStream *localStream = [WKRTCStreamManager shared].localStream;
    
    if(self.callType == WKRTCCallTypeVideo) {
        localStream.openVideo = true;
    }else{
        localStream.openVideo = false;
    }
    [localView renderStream:localStream];
    
}

-(id<WKRTCChatViewProtocol>) createP2PChatView:(WKRTCViewType)viewType participants:(NSArray<WKRTCParticipant *>*)participants {

    id<WKRTCChatViewProtocol> chatView = [[WKRTCUIManager shared] createChatView:participants mode:WKRTCModeP2P viewType:viewType callType:self.callType];
    __weak typeof(self) weakSelf = self;
    chatView.onMute = ^(BOOL on) {
        WKRTCStreamManager.shared.localStream.mute = on;
    };
    chatView.onHandsFree = ^(BOOL on) {
        [weakSelf switchAudioCategaryWithSpeaker:on];
    };
    __weak typeof(chatView) chatViewWeak = chatView;
   
    chatView.onSwitchCamera = ^{
      WKRTCStreamView *streamView =  [chatViewWeak streamView:weakSelf.options.uid];
        if(streamView) {
            [streamView switchCamera];
        }
    };
    chatView.onSwitch = ^{
        [weakSelf handleSwitchVideo];
    };
    return chatView;
}

-(id<WKRTCChatViewProtocol>) createConferenceChatView:(WKRTCViewType)viewType participants:(NSArray<WKRTCParticipant *>*)participants{
   
    id<WKRTCChatViewProtocol> chatView = [WKRTCUIManager.shared createChatView:participants mode:WKRTCModeConference viewType:viewType callType:WKRTCCallTypeAudio];
    __weak typeof(self) weakSelf = self;
    chatView.onSwitch = ^{
        [weakSelf handleSwitchVideo];
    };
    
    chatView.onHandsFree = ^(BOOL on) {
        [weakSelf switchAudioCategaryWithSpeaker:on];
    };
    
    chatView.onMute = ^(BOOL on) {
       WKRTCStreamView *streamView = [weakSelf.rtcChatView streamView:WKRTCManager.shared.options.uid];
        if(streamView) {
            streamView.mute = on;
        }
    };
    
    chatView.onAddParticipant = ^(AddParticipantCallback  _Nonnull callback) {
   
        [weakSelf.delegate rtcManager:weakSelf didInviteAtChannel:weakSelf.currentChannel data:@{
            @"participants":weakSelf.rtcChatView.participantUIDs?:@[],
        } complete:^(NSArray<NSString *> * uids) {
            
            callback(uids);
            
            [WKRTCAPIClient.shared invoke:weakSelf.currentRoomID uids:uids complete:^(NSError * _Nullable error) {
                if(error) {
                    [weakSelf showMsg:error.domain];
                }
            }];
        }];
    };
   
    return chatView;
}



-(void) endRTC {
    NSLog(@"endRTC....");
    if(!self.rtcChatView) {
        return;
    }
    if(WKRTCStreamManager.shared.joinRoomed) {
        [WKRTCStreamManager.shared leaveRoom:^(NSError * _Nullable error) {
            if(error) {
                NSLog(@"离开房间失败！->%@",error);
            }
        }];
    }
    [WKRTCVoicePlayUtil.shared  stopAll];
    [self removeDelegates];
    [RTCAudioSession.sharedInstance setIsAudioEnabled:NO];
    WKRTCMode mode = WKRTCModeConference;
    if(self.currentChannel.channelType == WK_PERSON) {
        mode = WKRTCModeP2P;
    }
    id<WKRTCClientProtocol> client = [WKRTCClientManager.shared getClient:mode];
    [client setReceiveMessage:false];
    [self.rtcChatView setStatus:WKRTCStatusEndTalking];
    
    __weak typeof(self) weakSelf = self;
    [self dismiss:(UIView*)self.rtcChatView complete:^{
        [weakSelf reset];
    }];
}


-(void) onHangup:(NSInteger) second {
    [self endRTC];
}

-(void) onRefuse {
    
    [self endRTC];
}

-(void) onCancel {

    [self endRTC];
}

//-(void) saveCallMsg:(NSInteger)type{
//    NSInteger second = self.rtcChatView.second;
//    NSString *content = @"";
//    NSString *fromUID;
//    if(type == WK_VIDEOCALL_REFUSE) {
//        if(self.isCallCreater) {
//            fromUID = self.currentChannel.channelId;
//        }else{
//            fromUID = WKApp.shared.loginInfo.uid;
//        }
//        content = @"拒绝通话";
//    }else if(type == WK_VIDEOCALL_CANCEL) {
//        if(self.isCallCreater) {
//            fromUID = WKApp.shared.loginInfo.uid;
//        }else{
//            fromUID = self.currentChannel.channelId;
//        }
//        content = @"已取消";
//    }else if(type == WK_VIDEOCALL_HANGUP) {
//        if(self.isCallCreater) {
//            fromUID = WKApp.shared.loginInfo.uid;
//        }else{
//            fromUID = self.currentChannel.channelId;
//        }
//    }
//    WKVideoCallSystemContent *callContent =  [WKVideoCallSystemContent initWithContent:content second:@(second) type:type];
//       callContent.callType = self.callType;
//    WKMessage *message = [[WKSDK shared].chatManager saveMessage:callContent channel:self.currentChannel fromUid:fromUID status:WK_MESSAGE_SUCCESS];
//    [WKSDK.shared.chatManager callRecvMessagesDelegate:@[message]];
//}


-(void) reset {
    [WKRTCStreamManager.shared reset];
    self.currentChannel = nil;
    self.currentRoomID = nil;
    self.isCallCreater = false;
    self.localStreamPublished = false;
    self.isTalking = false;
    self.switchVideoAlertShow = false;
    [self.rtcChatView end];
    self.rtcChatView = nil;
    
    NSLog(@"reset----->");
}

// 收到通话呼叫
-(void) onRecvCall:(WKChannel*)channel  roomID:(NSString*)roomID participants:(NSArray<WKRTCParticipant*>*)participants callType:(WKRTCCallType)callType{
    [WKRTCVoicePlayUtil.shared  receive];
    self.currentChannel = channel;
    self.isCallCreater = false;
    self.isTalking = true;
    self.callType = callType;
    [self initCall];
    WKRTCMode mode = WKRTCModeConference;
    if([WKRTCRoomUtil isPersonRoom:roomID]) {
        mode = WKRTCModeP2P;
    }
    __weak typeof(self) weakSelf = self;
    if(channel.channelType == WK_PERSON) {
        self.rtcChatView = [self createP2PChatView:WKRTCViewTypeResponse participants:participants];
    }else{
        self.rtcChatView = [self createConferenceChatView:WKRTCViewTypeResponse participants:participants];
    }
  
    
    [self.rtcChatView setOnAccepted:^{ // 接受通话
        id<WKRTCClientProtocol> client = [WKRTCClientManager.shared getClient:mode];
        [client setReceiveMessage:true];
        [weakSelf acceptPressed:roomID];
    }];
    
    [self.rtcChatView setOnHangup:^{ // 挂断
        [weakSelf handleHangup:roomID];
    }];
    
    // 显示UI
    UIView *view = (UIView*)self.rtcChatView;
    [self showView: view animation:YES];
    
    if(mode == WKRTCModeP2P) {
        // 渲染本地流到View
        [self renderLocalStreamToView];
    }
   
   
}

-(void) handleHangup:(NSString*)roomID {
    NSLog(@"########## handleHangup ##########");
    WKRTCMode mode = WKRTCModeConference;
    if([WKRTCRoomUtil isPersonRoom:roomID]) {
        mode = WKRTCModeP2P;
    }
    __weak typeof(self) weakSelf = self;
    if([self isCalling]) { // 正在通话
        if(self.currentChannel.channelType == WK_PERSON) {
            [WKRTCP2PSignalingManager.shared sendHangup:self.currentChannel.channelId time:weakSelf.rtcChatView.second callType:weakSelf.callType isCaller:weakSelf.isCallCreater].catch(^(NSError *error){
                [weakSelf showMsg:error.domain];
            });
        }
        
        [weakSelf endRTC];
        
        if(self.currentChannel.channelType == WK_GROUP) {
            // 挂断
            [WKRTCAPIClient.shared roomHangup:roomID complete:^(NSError * _Nullable error) {
                if(error) {
                    [weakSelf showMsg:error.domain];
                }
            }];
        }
    } else {
        if(mode == WKRTCModeP2P) {
            if(self.isCallCreater) {
                [WKRTCP2PSignalingManager.shared sendCancel:self.currentChannel.channelId callType: weakSelf.callType].catch(^(NSError *error){
                    [weakSelf showMsg:error.domain];
                });
            }else {
                
                [WKRTCP2PSignalingManager.shared sendRefuse:self.currentChannel.channelId callType:weakSelf.callType].catch(^(NSError *error){
                    [weakSelf showMsg:error.domain];
                });
            }
            [self endRTC];
        }else {
            [weakSelf endRTC];
            [WKRTCAPIClient.shared roomRefuse:roomID complete:^(NSError * _Nullable error) {
                if(error) {
                    NSLog(@"发送拒绝加入房间失败！-->%@",error);
                }
            }];
        }
        
    }
}

// 订阅某个房间的流 订阅后将通过WKRTCStreamManagerDelegate收到流
-(void) subscribeRoom:(NSString*)roomID token:(NSString*)token publishStream:(BOOL) publishStream {
    self.currentRoomID = roomID;
    WKRTCMode mode = WKRTCModeConference;
    if([WKRTCRoomUtil isPersonRoom:roomID]) {
        mode = WKRTCModeP2P;
    }
    __weak typeof(self) weakSelf = self;
   
    [WKRTCStreamManager.shared subscribe:token complete:^(NSError * _Nullable error) {
        if(error) {
            NSLog(@"订阅视频流失败！！->%@",error);
            [weakSelf endRTC];
            [[weakSelf getCurrentView] showHUDWithHide:@"订阅视频流失败！"];
            return;
        }
        if(publishStream) {
            [WKRTCStreamManager.shared publishLocalStream];
        }
       
    }];
   
}

-(UIView*) getCurrentView {
    return  [WKNavigationManager.shared.topViewController view];
}


// 通话是否接通
-(BOOL) isCalling {
    return self.rtcChatView.status == WKRTCStatusStartTalking || self.rtcChatView.status==WKRTCStatusP2PAccepted;
}

- (void)showView:(UIView*)view animation:(BOOL) animation {

    
    if (view.superview != nil) {
        return;
    }
    UIWindow *window = [self findWindow];
    [window endEditing:true];
    [window addSubview:view];
    
    if(animation) {
        [UIView animateWithDuration:0.2 animations:^{
            view.frame = window.bounds;
        } completion:^(BOOL finished) {
                
        }];
    }else{
        view.frame = window.bounds;
    }
    
}
         
-(UIWindow*) findWindow {
            
   return UIApplication.sharedApplication.delegate.window;
}

- (void)dismiss:(UIView*)view complete:(void(^)(void))complete {
    [UIView animateWithDuration:0.2 animations:^{
        CGRect rect = view.frame;
        rect.origin.y = 0-rect.size.height;
        view.frame = rect;
       
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        if(complete) {
            complete();
        }
    }];
}

-(void) presentViewController:(UIViewController*)vc {
    [[self getCurrentVC] presentViewController:vc animated:YES completion:nil];
}

//获取当前屏幕显示的viewcontroller
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}


// 接受房间的通话
-(void) acceptPressed:(NSString*)roomID {
    self.currentRoomID = roomID;
    self.rtcChatView.status = WKRTCStatusConnecting;
    
    [WKRTCVoicePlayUtil.shared  stopAll];

    
    // ---------- 加入到房间订阅流并开始推自己的流到房间内 ----------
    __weak typeof(self) weakSelf = self;
    [WKRTCStreamManager.shared joinRoom:roomID complete:^(NSString * _Nonnull token, NSError * _Nonnull error) {
        if(error) {
            NSLog(@"加入房间失败！->%@",error);
            [weakSelf endRTC];
            [[weakSelf getCurrentView] showHUDWithHide:@"加入房间失败！"];
            return;
        }
        if([WKRTCRoomUtil isPersonRoom:roomID]) {
            NSString *to = [WKRTCRoomUtil getToFromRoomID:roomID];
            [WKRTCP2PSignalingManager.shared sendAccepted:to callType:weakSelf.callType].catch(^(NSError *error){
                [weakSelf showMsg:error.domain];
            });
        }else{
            weakSelf.rtcChatView.status = WKRTCStatusConnecting;
            [weakSelf renderLocalStreamToView];
        }
        [weakSelf subscribeRoom:roomID token:token publishStream:true];
    }];

}

-(void) showMsg:(NSString*)msg {
    [(UIView*)self.rtcChatView showMsg:msg];
}

-(void) remoteStreamReady {
   
    [WKRTCVoicePlayUtil.shared  stopAll];
   
    [RTCAudioSession.sharedInstance setIsAudioEnabled:YES];
    
    if(self.currentChannel.channelType == WK_GROUP) {
        [WKRTCAPIClient.shared roomJoined:self.currentRoomID complete:^(NSError * _Nullable error) {
            if(error) {
                NSLog(@"请求已加入房间失败！->%@",error);
            }
        }];
    }
    // ---------- 改变视图为通话中状态 ----------
    [self.rtcChatView setStatus:WKRTCStatusStartTalking];
    
    if(self.callType == WKRTCCallTypeVideo || self.currentChannel.channelType == WK_GROUP) {
        // 扬声器
        WKAudioSessionManager.shared.isSpeaker = true;
    }else {
        // 非扬声器
        WKAudioSessionManager.shared.isSpeaker = false;
    }
    
    
    
    // ---------- 渲染本地的视频流到视图上 ----------
    
//    [self renderLocalStreamToView]; // 将本地流渲染到视图上
}

-(void) handleSwitchVideo {
    
    if(self.currentChannel.channelType == WK_PERSON) {
        if(self.callType == WKRTCCallTypeAudio) {
            if([self.rtcChatView isKindOfClass:[WKP2PChatView class]]) {
                [(WKP2PChatView*)self.rtcChatView bottomView].cameraSwitchBtn.on = NO;
            }
            [self showMsg:LLang(@"已发送视频通话请求给对方，请等待对方接受")];
            [WKRTCP2PSignalingManager.shared sendSwitchToVideo:self.currentChannel.channelId];
        }else{
            if([self.rtcChatView isKindOfClass:[WKP2PChatView class]]) {
                [(WKP2PChatView*)self.rtcChatView bottomView].cameraSwitchBtn.on = NO;
            }
            [self switchVoice];
            [WKRTCP2PSignalingManager.shared sendSwitchToVoice:self.currentChannel.channelId];
        }
    }else {
       WKRTCStreamView *streamView = [self.rtcChatView streamView:WKRTCManager.shared.options.uid];
        if(streamView) {
            streamView.openVideo = !streamView.openVideo;
        }
    }
   
   

}

-(void) onSwtichVideo {
    self.switchVideoAlertShow = true;
    [WKAlertUtil alert:@"对方请求切换为视频模式" buttonsStatement:@[@"拒绝",@"同意"] chooseBlock:^(NSInteger buttonIdx) {
        self.switchVideoAlertShow = false;
        if(buttonIdx == 0) {
            
            [WKRTCP2PSignalingManager.shared sendSwitchToVideoReply:self.currentChannel.channelId agree:NO];
        }else if(buttonIdx == 1) {
            if([self.rtcChatView isKindOfClass:[WKP2PChatView class]]) {
                [(WKP2PChatView*)self.rtcChatView bottomView].cameraSwitchBtn.on = YES;
            }
            [self switchVideo];
            [WKRTCP2PSignalingManager.shared sendSwitchToVideoReply:self.currentChannel.channelId agree:YES];
        }
    }];
}

-(void) switchVideo {
    self.callType = WKRTCCallTypeVideo;
    WKRTCStreamView *streamView = [self.rtcChatView streamView:self.options.uid];
    if(streamView) {
        [streamView setOpenVideo:YES];
    }
    [self.rtcChatView setCallType:WKRTCCallTypeVideo animation:YES];
    
    [RTCAudioSession.sharedInstance lockForConfiguration];
    [self switchAudioCategaryWithSpeaker:YES];
    [RTCAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    [RTCAudioSession.sharedInstance unlockForConfiguration];
}

-(void) switchVoice {
    self.callType = WKRTCCallTypeAudio;
    
    WKRTCStreamView *streamView = [self.rtcChatView streamView:self.options.uid];
    if(streamView) {
        [streamView setOpenVideo:NO];
    }
    [self.rtcChatView setCallType:WKRTCCallTypeAudio animation:YES];
    
    [RTCAudioSession.sharedInstance lockForConfiguration];
    [self switchAudioCategaryWithSpeaker:NO];
    [RTCAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    [RTCAudioSession.sharedInstance unlockForConfiguration];
}

-(void) onSwitchVoice {
    if([self.rtcChatView isKindOfClass:[WKP2PChatView class]]) {
        [(WKP2PChatView*)self.rtcChatView bottomView].cameraSwitchBtn.on = NO;
    }
    [self switchVoice];
}

-(void) onSwtichVideoReply:(BOOL) agree {
    if(agree) {
        if([self.rtcChatView isKindOfClass:[WKP2PChatView class]]) {
            [(WKP2PChatView*)self.rtcChatView bottomView].cameraSwitchBtn.on = YES;
        }
        [self switchVideo];
        
    }else{
        [self showMsg:LLang(@"对方同意了您的请求")];
    }
}

// 对方接受通话
-(void) onAcceptCall:(WKChannel*)channel {
    if(self.rtcChatView.status == WKRTCStatusStartTalking) {
        return;
    }
    self.rtcChatView.status = WKRTCStatusConnecting;
   
    [self remoteStreamReady];
//    [RTCAudioSession.sharedInstance setIsAudioEnabled:YES];
//    [self.rtcChatView setStatus:WKRTCStatusStartTalking];
//    [WKRTCStreamManager.shared publishLocalStream];
//    [self publishStream];
}

#pragma mark -- WKRTCClientProtocolDelegate

- (void)rtcClientDidEnd:(id<WKRTCClientProtocol>)rtcClient to:(NSString *)to {
    NSLog(@"###### rtcClientDidEnd->%@",to);
    if(self.currentChannel.channelType == WK_PERSON && [self.currentChannel.channelId isEqualToString:to]) {
        [self endRTC];
    }
}


#pragma mark -- WKAudioSessionManagerDelegate

- (void)audioSessionManagerDidRouteChange:(WKAudioSessionManager *)manager {
    if(!self.rtcChatView) {
        return;
    }
    [self setOutputAudio];
    if(manager.availablePorts.count>1) {
        UIView *view = (UIView*)self.rtcChatView;
        [view showMsg:@"切换为耳机设备"];
    }
}

#pragma mark -- WKRTCStreamManagerDelegate

-(void) rtcStreamManager:(WKRTCStreamManager*)manager didAddStream:(WKRTCStream*)stream {
    WKRTCStreamView *streamView = [self.rtcChatView streamView:stream.uid];
    if(streamView) {
        NSLog(@"###### didUpdateStream--->%@",streamView.stream);
        if(streamView.stream) {
            [streamView unreaderStream];
        }
        [streamView renderStream:stream];
        if(self.currentChannel.channelType == WK_PERSON && [stream.uid isEqualToString:self.currentChannel.channelId]) {
            [self onAcceptCall:self.currentChannel];
        }
        if(self.currentChannel.channelType == WK_GROUP && ![stream.uid isEqualToString:WKRTCManager.shared.options.uid] && self.rtcChatView.status != WKRTCStatusStartTalking) {
            [self onAcceptCall:self.currentChannel];
        }
    }
}

#pragma mark -- WKChatManagerDelegate

- (void)onRecvMessages:(WKMessage *)message left:(NSInteger)left {
    if(self.currentChannel && ![self.currentChannel isEqual:message.channel]) {
        return;
    }
    NSInteger contentType =  message.contentType;
    NSInteger channelType = message.channel.channelType;

    if(channelType == WK_PERSON) {
        if(contentType == WK_VIDEOCALL_SWITCH_TO_VIDEO) { // 请求切换到视频通话
            [self onSwtichVideo];
        }else if(contentType == WK_VIDEOCALL_SWITCH_TO_VIDEO_REPLY) { // 回应视频通话请求
            WKVideoCallSystemContent *content = (WKVideoCallSystemContent*)message.content;
            [self onSwtichVideoReply:content.agree];
        }else if(contentType == WK_VIDEOCALL_SWITCH) { // 切换到语音
            [self onSwitchVoice];
        }
    }
   
}

#pragma mark -- WKCMDManagerDelegate

- (void)cmdManager:(WKCMDManager *)manager onCMD:(WKCMDModel *)model {
    
    NSString *cmd = model.cmd;
    NSDictionary *param = model.param;
    if([cmd isEqualToString:WKCMDRTCRoomInvoke]) { // 会议邀请
        if(self.isTalking) {
            NSLog(@"正在通话中，不再处理会议通话命令！");
            return;
        }
        if(model.timestamp + self.options.p2pCallTimeout<[[NSDate date] timeIntervalSince1970]) { // 超时不接听
            NSLog(@"超时不接听---->");
            return;
        }
        NSString *inviter = param[@"inviter"];
        NSString *roomID = param[@"room_id"];
        NSArray *participantIDs = param[@"participants"];
        
        NSString *channelID =  param[@"channel_id"]?:@"";
        WKChannel *channel;
        
        if(channelID && ![channelID isEqualToString:@""]) {
            channel = [WKChannel channelID:channelID channelType:[param[@"channel_type"] integerValue]];
        }
        
        if(participantIDs && participantIDs.count>0){
            NSMutableArray<WKRTCParticipant*> *participants = [NSMutableArray array];
            WKRTCParticipant *creater = [[WKRTCParticipant alloc] initWithUID:inviter];
            creater.role = WKRTCParticipantRoleInviter;
            creater.avatar = [NSURL URLWithString:[WKAvatarUtil getAvatar:inviter]];
            [participants addObject:creater];
            for (NSString *participantID in participantIDs) {
                WKRTCParticipant *p = [[WKRTCParticipant alloc] initWithUID:participantID];
                p.avatar = [NSURL URLWithString:[WKAvatarUtil getAvatar:participantID]];
                if([participantID isEqualToString:inviter]) {
                    continue;
                }
                [participants addObject:p];
            }
            [self onRecvCall:channel roomID:roomID participants:participants callType:WKRTCCallTypeAudio];
        }
    } else if([cmd isEqualToString:WKCMDRTCRoomRefuse]) {
        NSString *roomID = param[@"room_id"];
        NSString *participant = param[@"participant"];
        if(participant && [roomID isEqualToString:self.currentRoomID]) {
            if(self.rtcChatView) {
                [self.rtcChatView leave:participant reason:LLang(@"拒绝加入")];
            }
        }
    } else if([cmd isEqualToString:WKCMDRTCP2PInvoke]) { // 个人通话邀请
        
        NSString *fromUID = @"";
        if(param[@"from_uid"]) {
            fromUID = param[@"from_uid"];
        }
        
        if([fromUID isEqualToString:WKApp.shared.loginInfo.uid]) { // 说明是自己其他设备发起的通话
            return;
        }
        
        if(self.isTalking) {
            NSLog(@"正在通话中，不再处理通话请求！");
            return;
        }
        
        if(model.timestamp + self.options.p2pCallTimeout<[[NSDate date] timeIntervalSince1970]) { // 超时不接听
            NSLog(@"超时不接听---->");
            return;
        }
        
      
        NSInteger callType = WKCallTypeAudio;
        if(param[@"call_type"]) {
            callType = [param[@"call_type"] integerValue];
        }
        
        NSMutableArray<WKRTCParticipant*> *participants = [NSMutableArray array];
        WKRTCParticipant *p = [[WKRTCParticipant alloc] initWithUID:fromUID];
        p.role = WKRTCParticipantRoleInviter;
        [participants addObject:p];
        
        p = [[WKRTCParticipant alloc] initWithUID:WKRTCManager.shared.options.uid];
        [participants addObject:p];
        [self onRecvCall:[WKChannel personWithChannelID:fromUID] roomID:[WKRTCRoomUtil genPersonRoomID:WKRTCManager.shared.options.uid toUID:fromUID] participants:participants callType:callType];
        
    }else if([cmd isEqualToString:WKCMDRTCP2PAccept]) {
        NSString *fromUID = @"";
        if(param[@"from_uid"]) {
            fromUID = param[@"from_uid"];
        }
        if([fromUID isEqualToString:WKApp.shared.loginInfo.uid]) {
            if(!self.rtcChatView || self.rtcChatView.status != WKRTCStatusUnknown) {
                return;
            }
            [self onCancel]; // 说明是自己其他设备接听了
            [WKNavigationManager.shared.topViewController.view showHUDWithHide:LLang(@"通话被其他设备接听")];
            return;
        }
        
    } else if([cmd isEqualToString:WKCMDRTCP2PHangup]) { // 挂断(接通后)
        NSString *uid = param[@"uid"]?:@"";
        NSNumber *second = param[@"second"]?:@(0);
        if(uid && [uid isEqualToString:self.currentChannel.channelId]) {
            [self onHangup:second.intValue];
        }
    }else if([cmd isEqualToString:WKCMDRTCP2PRefuse]) { // 拒绝（未接通）
        NSString *uid = param[@"uid"]?:@"";
        if([uid isEqualToString:WKApp.shared.loginInfo.uid]) { // 自己其他设备拒绝了通话
            if(self.rtcChatView) {
                [self endRTC];
                return;
            }
        }
        if(uid && [uid isEqualToString:self.currentChannel.channelId]) {
            [self onRefuse];
        }
    }else if([cmd isEqualToString:WKCMDRTCP2PCancel]) { // 取消（发起者取消通话）
        NSString *uid = param[@"uid"]?:@"";
        if([uid isEqualToString:WKApp.shared.loginInfo.uid]) { // 自己其他设备取消了通话
            if(self.rtcChatView) {
                [self endRTC];
                return;
            }
        }
        if(uid && [uid isEqualToString:self.currentChannel.channelId]) {
            [self onCancel];
        }
    }
}

@end
