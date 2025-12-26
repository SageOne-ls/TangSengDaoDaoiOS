//
//  WKRTCOWTClientImpl.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCOWTClientImpl.h"
#import <OWT/OWT.h>
#import <WebRTC/WebRTC.h>
#import "WKTP2PSignalingChannel.h"
#import "WKRTCStreamManager.h"
#import "WKRTCManager.h"
#import "WKRTCAPIClient.h"
#import "WKRTCOWTStream.h"
@interface WKRTCOWTP2PClientImpl ()<RTCPeerConnectionDelegate,OWTP2PSignalingChannelDelegate>

//@property(nonatomic,strong) OWTP2PClient *client;

@property(nonatomic,strong) WKTP2PSignalingChannel *p2pSignalingChannel;

@property(nonatomic,strong) RTCPeerConnection *client;

@property(nonatomic,strong) RTCPeerConnectionFactory *factory;

@property (nonatomic, strong)RTCMediaConstraints *sdpConstrains;

@property(nonatomic,copy) NSString *to;



@end

@implementation WKRTCOWTP2PClientImpl

static WKRTCOWTP2PClientImpl *_instance;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCOWTP2PClientImpl *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}


- (void)connect:(NSString *)token onSuccess:(void (^)(NSString * _Nonnull))onSuccess onFailure:(void (^)(NSError * _Nonnull))onFailure {
    self.to = WKRTCManager.shared.currentChannel.channelId;
    NSLog(@"###### p2pSignalingChannel connect");
    // TODO: 这里需要执行下self.p2pSignalingChannel 如果p2pSignalingChannel没执行init则就不会监听到消息，webrtc的消息就会丢掉，导致接不通
    // 虽然目前执行self.p2pSignalingChannel connect 没太多意义 但是别去掉这句代码
    [self.p2pSignalingChannel connect:token onSuccess:onSuccess onFailure:onFailure];
//    if(onSuccess) {
//        onSuccess(@"");
//    }
    
//    [self.client connect:token onSuccess:onSuccess onFailure:onFailure];
}

- (void)disconnectWithOnSuccess:(nullable void (^)(void))onSuccess
                      onFailure:(nullable void (^)(NSError*))onFailure {
    
    NSLog(@"###### p2pSignalingChannel disconnect");
    [self.p2pSignalingChannel disconnectWithOnSuccess:onSuccess onFailure:onFailure];
    [self.client setDelegate:nil];
    [self.client close];
    self.to = nil;
    self.client = nil;
    if(onSuccess) {
        onSuccess();
    }
}



-(void) publishStream:(WKRTCStream*)stream to:(NSString*)to{
    RTCMediaStream *mediaStream = stream.stream;
    [self.client addStream:mediaStream];
    
    
    
    NSLog(@"###### publishStream-->%@",to);
    
    NSString *micTrackId = mediaStream.audioTracks.firstObject.trackId;
    NSString *cameraTrackId = mediaStream.videoTracks.firstObject.trackId;
    
    //chat-track-sources
    NSArray *chatTrackSources = @[@{@"id":micTrackId,@"source":@"mic"},@{@"id":cameraTrackId,@"source":@"camera"}];
    
    [self sendMessage:chatTrackSources type:@"chat-track-sources" retryCount:3];
    
    //chat-stream-info
    NSDictionary *chatStreamInfo = @{@"id":mediaStream.streamId,@"source":@{@"audio":@"mic",@"video":@"camera"},@"tracks":@[micTrackId,cameraTrackId]};
    [self sendMessage:chatStreamInfo type:@"chat-stream-info" retryCount:3];
    
    __weak typeof(self) weakSelf = self;
    [self.client offerForConstraints:self.sdpConstrains completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        [weakSelf.client setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"##### setLocalDescriptionFailed %@",error);
            }
            else {
                [weakSelf sendSDP:sdp];
            }
        }];
    }];

   
}
- (void)sendSDP:(RTCSessionDescription *)sdp{
    NSString *type = @"answer";
    if (sdp.type == RTCSdpTypeOffer) {
        type = @"offer";
    }
    NSDictionary *dict = @{@"sdp":sdp.sdp,@"type":type};
    [self sendMessage:dict type:@"chat-signal" retryCount:3];
}

- (void)sendCandidate:(RTCIceCandidate *)candidate {
    NSDictionary *dict = @{@"candidate":candidate.sdp,@"type":@"candidates",@"sdpMLineIndex":[NSString stringWithFormat:@"%d",candidate.sdpMLineIndex],@"sdpMid":candidate.sdpMid};
    [self sendMessage:dict type:@"chat-signal" retryCount:3];
}

- (void)sendMessage:(id)msgObj type:(NSString *)type retryCount:(NSInteger)retryCount {
    if (msgObj == nil || type == nil || type.length == 0) {
         return;
    }
    NSDictionary *sendParam = @{@"data":msgObj,@"type":type};
    NSString *jsonStr = [self dicToJson:sendParam];
    
    __weak typeof(self) weakSelf = self;
    [self.p2pSignalingChannel sendMessage:jsonStr to:self.to onSuccess:^{
    } onFailure:^(NSError *e) {
         DDLogInfo(@"### 发送信令消息失败");
         if (retryCount>0) {
              DDLogInfo(@"#### 重发信令消息");
              DDLogInfo(@"%@",msgObj);
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [weakSelf sendMessage:msgObj type:type  retryCount:retryCount-1];
              });
         }
    }];
}

- (NSString*)dicToJson:(NSDictionary*)dic {
    NSError*parseError =nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (RTCPeerConnectionFactory *)factory {
    if(!_factory) {
        _factory = [RTCPeerConnectionFactory sharedInstance];
    }
    return _factory;
}

//getters
- (RTCMediaConstraints *)sdpConstrains {
    if (_sdpConstrains == nil) {
        NSDictionary *contrains = @{@"OfferToReceiveAudio": @"true", @"OfferToReceiveVideo": @"true"};
        _sdpConstrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:contrains optionalConstraints:nil];
    }
    return _sdpConstrains;
}

- (RTCPeerConnection *)client {
    if(!_client) {

        RTCConfiguration *rtcConfiguration = [[RTCConfiguration alloc] init];
        rtcConfiguration.iceTransportPolicy = RTCIceTransportPolicyAll;
        rtcConfiguration.disableIPV6 = YES;
        rtcConfiguration.maxIPv6Networks = 2; // iOS系统有同时连接数限制，所以这里也要限制
        
        //实时传输控制协议多路策略，negotiate、require，第一个是获取实时传输控制协议策略和实时传输协议策略，第二个只获取实时传输协议策略，如果另一个客户端不支持实时传输控制协议，那么协商就会失败。客户端测试发现Require比较适合移动客户端。
        rtcConfiguration.rtcpMuxPolicy = RTCRtcpMuxPolicyRequire;
        //协商策略，balanced、max-compat、max-bundle,基本上是选择max-bundle，主要是防止另一个客户端属于策略不可协商型。
        rtcConfiguration.bundlePolicy = RTCBundlePolicyMaxBundle;
        
        rtcConfiguration.sdpSemantics = RTCSdpSemanticsPlanB; // 这个不使用RTCSdpSemanticsPlanB有时候接不通
        
        NSMutableArray *ices = [NSMutableArray array];
        
        if(WKApp.shared.config.rtcIces && WKApp.shared.config.rtcIces.count>0) {
            for (WKRTCIceServer *iceServer in WKApp.shared.config.rtcIces) {
                if(iceServer.username && iceServer.credential) {
                    [ices addObject:[[RTCIceServer alloc] initWithURLStrings:iceServer.urlStrings username:iceServer.username credential:iceServer.credential]];
                }else {
                    [ices addObject:[[RTCIceServer alloc]initWithURLStrings:iceServer.urlStrings]];
                }
            }
            rtcConfiguration.iceServers=ices;
        }
        
       _client = [self.factory peerConnectionWithConfiguration:rtcConfiguration constraints:self.sdpConstrains delegate:self];
    
    }
    return _client;
}

-(void) handleChatSignalMessage:(NSDictionary *)dict  {
    NSDictionary *data = dict[@"data"];
    if (data[@"sdp"] != nil) {
        RTCSdpType type = ([data[@"type"] isEqualToString:@"answer"]?RTCSdpTypeAnswer:RTCSdpTypeOffer);
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:data[@"sdp"]];
        [self setRemoteSDP:sdp type:type];
    }
    else if (data[@"candidate"] != nil) {
        RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:data[@"candidate"] sdpMLineIndex:[data[@"sdpMLineIndex"] intValue] sdpMid:data[@"sdpMid"]];
        [self.client addIceCandidate:candidate];
    }
}


- (void)setRemoteSDP:(RTCSessionDescription *)sdp type:(RTCSdpType)type {
    __weak typeof(self) weakSelf = self;
    [self.client setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
        if (error == nil) {
            if (type == RTCSdpTypeOffer) {
                [weakSelf.client answerForConstraints:weakSelf.sdpConstrains completionHandler:^(RTCSessionDescription * _Nullable ansSDP, NSError * _Nullable error) {
                    if(error) {
                        NSLog(@"#### answerForConstraintsError %@",error);
                        return;
                    }
                    [weakSelf.client setLocalDescription:ansSDP completionHandler:^(NSError * _Nullable error) {
                        if (error) {
                            NSLog(@"#### setLocalDescriptionError %@",error);
                        }
                    }];
                    [weakSelf sendSDP:ansSDP];
                    
                    if(WKRTCManager.shared.isCallCreater && WKRTCManager.shared.currentChannel && WKRTCManager.shared.currentChannel.channelType == WK_PERSON) {
                        NSLog(@"setRemoteSDP-----publish---->");
                        [WKRTCStreamManager.shared publishLocalStream];
                    }
                   
                }];
            }
        }
        else {
            NSLog(@"#### setRemoteDescriptionError %@",error);
//            DDLogInfo(@"##### sdp = %@",sdp.sdp);
        }
    }];
}

//json格式字符串转字典：
- (NSDictionary*)dictFromJsonString:(NSString*)jsonString {
    if(jsonString ==nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError*err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        return nil;
    }
    return dic;
}

- (WKTP2PSignalingChannel *)p2pSignalingChannel {
    if(!_p2pSignalingChannel) {
        _p2pSignalingChannel = [[WKTP2PSignalingChannel alloc] init];
        _p2pSignalingChannel.delegate = self;
    }
    return _p2pSignalingChannel;
}

#pragma mark -- RTCPeerConnectionDelegate

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didAddStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"###### didAddStream->%@",WKRTCManager.shared.currentChannel.channelId);
    WKRTCStream *limStream = [[WKRTCStream alloc] initStream:stream uid:WKRTCManager.shared.currentChannel.channelId];
    [WKRTCStreamManager.shared addOrUpdateStream:limStream];
    
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    NSLog(@"##### didChangeIceConnectionState %ld",(long)newState);
//    if(newState == RTCIceConnectionStateDisconnected) {
//        if(self.delegate && [self.delegate respondsToSelector:@selector(rtcClientDidEnd:to:)]) {
//            lim_dispatch_main_async_safe(^{
//                [self.delegate rtcClientDidEnd:self to:self.to];
//            });
//            
//        }
//    }
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    NSLog(@"##### didChangeIceGatheringState %ld",(long)newState);
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    NSLog(@"##### didChangeSignalingState %ld",(long)stateChanged);
    
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didGenerateIceCandidate:(nonnull RTCIceCandidate *)candidate {
    NSLog(@"##### didGenerateIceCandidate  %@",candidate.sdp);
    [self.client addIceCandidate:candidate];
    [self sendCandidate:candidate];
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didOpenDataChannel:(nonnull RTCDataChannel *)dataChannel {
    NSLog(@"##### didOpenDataChannel");
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"##### didRemoveIceCandidates");
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveStream:(nonnull RTCMediaStream *)stream {
    NSLog(@"##### didRemoveStream");
}

- (void)peerConnectionShouldNegotiate:(nonnull RTCPeerConnection *)peerConnection {
    NSLog(@"##### peerConnectionShouldNegotiate");
}

#pragma mark -- OWTP2PSignalingChannelDelegate

- (void)channelDidDisconnect:(id<OWTP2PSignalingChannelProtocol>)channel {
    NSLog(@"##### channelDidDisconnect");
}

- (void)channel:(id<OWTP2PSignalingChannelProtocol>)channel didReceiveMessage:(NSString *)message from:(NSString *)senderId {
    
    if(!self.receiveMessage) {
        NSLog(@"#### no allow receiveMessage--->");
        return;
    }
    
    NSLog(@"didReceiveMessage-------------->1--->");
    
    NSDictionary *dict = [self dictFromJsonString:message];
    if (dict) {
        if ([dict[@"type"] isEqualToString:@"chat-signal"]) {
            [self handleChatSignalMessage:dict];
        }
        else if ([dict[@"type"] isEqualToString:@"chat-track-sources"]) {
            NSMutableArray *tmpArray = NSMutableArray.array;
            [dict[@"data"] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [tmpArray addObject:obj[@"id"]];
            }];
            [self sendMessage:tmpArray type:@"chat-tracks-added" retryCount:3];
        }
    }
    NSLog(@"didReceiveMessage-------------->2--->");
}


@synthesize allowedRemoteIds;
@synthesize receiveMessage;

@synthesize delegate;

@end

@interface WKRTCOWTConferenceClientImpl ()<OWTConferenceClientDelegate,WKRTCOWTStreamDelegate>

@property(nonatomic,strong) OWTConferenceClient *client;
@property(nonatomic,assign) BOOL createNewClient;

@property(nonatomic,strong) NSMutableDictionary<NSString*,OWTConferenceParticipant*> *participantDict;
@property(nonatomic,strong) NSMutableDictionary<NSString*,NSNumber*> *cacheAudiEnergyDict; // 缓存每个参与者的音量

@property(nonatomic,strong) NSTimer *subscriptionStatusTimer;

@end

@implementation WKRTCOWTConferenceClientImpl

static WKRTCOWTConferenceClientImpl *_confferenceInstance;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _confferenceInstance = [super allocWithZone:zone];
    });
    return _confferenceInstance;
}
+ (WKRTCOWTConferenceClientImpl *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _confferenceInstance = [[self alloc] init];
        _confferenceInstance.createNewClient = true;
        
    });
    return _confferenceInstance;
}

- (NSMutableDictionary<NSString *,OWTConferenceParticipant *> *)participantDict {
    if(!_participantDict) {
        _participantDict = [NSMutableDictionary dictionary];
    }
    return _participantDict;
}

- (NSMutableDictionary *)cacheAudiEnergyDict {
    if(!_cacheAudiEnergyDict) {
        _cacheAudiEnergyDict = [NSMutableDictionary dictionary];
    }
    return _cacheAudiEnergyDict;
}

- (OWTConferenceClient *)client {
    if(!_client) {

        OWTConferenceClientConfiguration* config=[[OWTConferenceClientConfiguration alloc]init];
        
        config.rtcConfiguration=[[RTCConfiguration alloc] init];
        // ices
        NSMutableArray *ices = [NSMutableArray array];
        if(WKApp.shared.config.rtcIces && WKApp.shared.config.rtcIces.count>0) {
            for (WKRTCIceServer *iceServer in WKApp.shared.config.rtcIces) {
                if(iceServer.username && iceServer.credential) {
                    [ices addObject:[[RTCIceServer alloc] initWithURLStrings:iceServer.urlStrings username:iceServer.username credential:iceServer.credential]];
                }else {
                    [ices addObject:[[RTCIceServer alloc]initWithURLStrings:iceServer.urlStrings]];
                }
            }
            config.rtcConfiguration.iceServers=ices;
        }
        _client=[[OWTConferenceClient alloc]initWithConfiguration:config];
        _client.delegate=self;
        
        [self startSubscriptionStatusTimer];
    }
    return _client;
}

- (void)subscribe:(NSString *)token complete:(void (^)(NSError * _Nullable))complete {
    __weak typeof(self) weakSelf = self;
    [self.client joinWithToken:token onSuccess:^(OWTConferenceInfo * owtConferenceInfo) {
        [weakSelf joinRoomWithConferenceInfo:owtConferenceInfo];
        if(complete) {
            complete(nil);
        }
    } onFailure:^(NSError * err) {
        if(complete) {
            complete(err);
        }
    }];
}


-(void) joinRoomWithConferenceInfo:(OWTConferenceInfo*)conferenceInfo {
    __weak typeof(self) weakSelf = self;
    for (OWTRemoteStream *stream in conferenceInfo.remoteStreams) {
        NSLog(@"attrs--->%@",stream.attributes);
        NSLog(@"origin--->%@",stream.origin);
        for (OWTConferenceParticipant  *participant in conferenceInfo.participants) {
            if([participant.participantId isEqualToString:stream.origin]) {
                
                [self subscribeStream:stream complete:^(OWTConferenceSubscription *sub, NSError *error) {
                    [weakSelf subscribeSuccess:sub stream:stream participant:participant];
                }];
                break;
            }
        }
    }
}


-(void) leaveConference:(void(^)(NSError *error))complete {
    __weak typeof(self) weakSelf = self;
    [self.client leaveWithOnSuccess:^{
        NSLog(@"leaveWithOnSuccess----->success");
        if(complete) {
            complete(nil);
        }
        weakSelf.createNewClient = true;
    } onFailure:^(NSError * err) {
        NSLog(@"leaveConference----->error->%@",err);
        if(complete) {
            complete(err);
        }
        weakSelf.createNewClient = true;
    }];
}

-(void) reset {
    [self stopSubscriptionStatusTimer];
    [self.participantDict removeAllObjects];
    self.client.delegate = nil;
    self.client = nil;
}

-(void) sendEnableVideoToParticipant:(NSString*) participantID {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"cmd":@"enableVideo"} options:0 error:nil];
    
    [self.client send:[[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding]  to:participantID onSuccess:^{
        
    } onFailure:^(NSError * error) {
        NSLog(@"发送启用视频的消息失败！->%@",error);
    }];
}

-(void) subscribeSuccess:(OWTConferenceSubscription *)sub stream:(OWTRemoteStream*)stream participant:(OWTConferenceParticipant*) participant{
    
    NSLog(@"sub------>%@",participant.userId);
    
    self.participantDict[participant.participantId] = participant;
    
    NSString *uid = participant.userId;
    WKRTCOWTStream *limstream = [[WKRTCOWTStream alloc] initStream:stream uid:uid];
    limstream.delegate = self;
    limstream.subscription = sub;
    limstream.participant = participant;
    [WKRTCStreamManager.shared addOrUpdateStream:limstream];
    
    if(WKRTCStreamManager.shared.localStream.openVideo) {
        [self sendEnableVideoToParticipant:participant.participantId];
    }
    
}

-(void) startSubscriptionStatusTimer {
    if(self.subscriptionStatusTimer) {
        [self.subscriptionStatusTimer invalidate];
        self.subscriptionStatusTimer = nil;
    }
    self.subscriptionStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(subscriptionStatusTimerClick) userInfo:nil repeats:true];
}

-(void) stopSubscriptionStatusTimer {
    if(self.subscriptionStatusTimer) {
        [self.subscriptionStatusTimer invalidate];
        self.subscriptionStatusTimer = nil;
    }
}

// 定时查询subscription的状态
-(void) subscriptionStatusTimerClick {
    __weak typeof(self) weakSelf = self;
    
    [[WKRTCStreamManager.shared streamAll] enumerateObjectsUsingBlock:^(WKRTCStream * _Nonnull stream, NSUInteger idx, BOOL * _Nonnull stop) {
        WKRTCOWTStream *owtStream = (WKRTCOWTStream*)stream;
        if(owtStream.subscription) {
            NSString *uid = owtStream.participant.userId;
            WKRTCStreamView *streamView = [WKRTCManager.shared.rtcChatView streamView:uid];
            if(!streamView) {
                return;
            }
            [owtStream.subscription statsWithOnSuccess:^(NSArray<RTCLegacyStatsReport *> * stats) {
                [weakSelf handleAudioEnergy:stats stream:streamView uid:uid];
            } onFailure:^(NSError * err) {
                NSLog(@"查询subscription状态失败！ %@",err);
            }];
        }else if(owtStream.conferencePublication) {
            NSString *uid = WKRTCManager.shared.options.uid;
            WKRTCStreamView *streamView = [WKRTCManager.shared.rtcChatView streamView:uid];
            if(!streamView) {
                return;
            }
            [owtStream.conferencePublication statsWithOnSuccess:^(NSArray<RTCLegacyStatsReport *> * stats) {
                [weakSelf handleAudioEnergy:stats stream:streamView uid:uid];
            } onFailure:^(NSError * err) {
                NSLog(@"查询publication状态失败！ %@",err);
            }];
        }
        
    }];
}

-(void) handleAudioEnergy:(NSArray<RTCLegacyStatsReport *> *)stats stream:(WKRTCStreamView*)streamView uid:(NSString*)uid{
    CGFloat audioEnergy = [self getTotalAudioEnergy:stats];
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat oldAudioEnergy = self.cacheAudiEnergyDict[uid]?[self.cacheAudiEnergyDict[uid] floatValue]:0.0f;
        if (audioEnergy - oldAudioEnergy >= 0.0005) { // is talking
            streamView.talking = true;
        }else{
            streamView.talking = false;
        }
        self.cacheAudiEnergyDict[uid] = @(audioEnergy);
    });
}

// 获取音量
- (CGFloat)getTotalAudioEnergy:(NSArray<RTCLegacyStatsReport *> *)stats {
    __block CGFloat result = 0.0;
    [stats enumerateObjectsUsingBlock:^(RTCLegacyStatsReport * _Nonnull stat, NSUInteger idx, BOOL * _Nonnull stop) {
        [stat.values enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            if([key isEqualToString:@"totalAudioEnergy"]) {
                *stop = true;
                result = value.floatValue;
                
            }
        }];
    }];
    return result;
}

-(void) subscribeStream:(OWTRemoteStream*)stream complete:(void(^)(OWTConferenceSubscription *pub,NSError *error))complete{

    
    OWTConferenceSubscribeOptions *options = [OWTConferenceSubscribeOptions new];
    OWTConferenceVideoSubscriptionConstraints *video = [OWTConferenceVideoSubscriptionConstraints new];
    OWTVideoCodecParameters *videoCodec = [[OWTVideoCodecParameters alloc] init];
    videoCodec.name = OWTVideoCodecH264;
    video.codecs = @[videoCodec];
    options.video = video;

    [self.client subscribe:stream withOptions:options onSuccess:^(OWTConferenceSubscription * sub) {
        complete(sub,nil);
    } onFailure:^(NSError * err) {
        NSLog(@"订阅流失败！--->%@",err);
        complete(nil,err);
    }];
}



-(void) createConference:(NSArray<NSString*>*)participants complete:(void(^)(NSString *roomID,NSString *token,NSError *error))complete{
    if(!participants||participants.count == 0) {
        return;
    }
    NSMutableArray<NSString*> *newParticipantIDs = [NSMutableArray array];
    for (NSString *participantID in participants) {
        if([participantID isEqualToString:WKApp.shared.loginInfo.uid]) {
            continue;
        }
        [newParticipantIDs addObject:participantID];
    }
    
    WKCreateRoomReq *req = [WKCreateRoomReq new];
    req.uids = newParticipantIDs;
    if(WKRTCManager.shared.currentChannel) {
        req.channelID = WKRTCManager.shared.currentChannel.channelId;
        req.channelType = WKRTCManager.shared.currentChannel.channelType;
    }
    [WKRTCAPIClient.shared createRoom:req complete:^(WKCreateRoomResp * _Nonnull resp, NSError * _Nonnull error) {
        if(error) {
            if(complete) {
                complete(nil,nil,error);
            }
            return;
        }
        
        [WKRTCAPIClient.shared getToken:resp.roomID complete:^(NSString * _Nonnull token, NSError * _Nonnull error) {
            if(error) {
                if(complete) {
                    complete(nil,nil,error);
                }
                return;
            }
            if(complete) {
                complete(resp.roomID,token,nil);
            }
            
        }];
    }];
}


-(void)publishStream:(WKRTCStream*)stream to:(NSString*)to{
    OWTPublishOptions* options=[[OWTPublishOptions alloc] init];
    OWTAudioCodecParameters* opusParameters=[[OWTAudioCodecParameters alloc] init];
    opusParameters.name=OWTAudioCodecOpus;
    OWTAudioEncodingParameters *audioParameters=[[OWTAudioEncodingParameters alloc] init];
    audioParameters.codec=opusParameters;
    options.audio=[NSArray arrayWithObjects:audioParameters, nil];
    OWTVideoCodecParameters *h264Parameters=[[OWTVideoCodecParameters alloc] init];
    h264Parameters.name=OWTVideoCodecH264;
    OWTVideoEncodingParameters *videoParameters=[[OWTVideoEncodingParameters alloc]init];
    videoParameters.codec=h264Parameters;
    options.video=[NSArray arrayWithObjects:videoParameters, nil];
    NSLog(@"publishStream---->发布流");
    [self.client publish:stream.stream withOptions:options onSuccess:^(OWTConferencePublication * pub) {
        NSLog(@"pub---->%@",pub);
        if([stream isKindOfClass:[WKRTCOWTStream class]]) {
            ( (WKRTCOWTStream*)stream).conferencePublication = pub;
        }
    } onFailure:^(NSError * error) {
        NSLog(@"推流失败！->%@",error);
    }];
    
}



#pragma mark -- OWTConferenceClientDelegate

- (void)conferenceClientDidDisconnect:(OWTConferenceClient *)client {
    NSLog(@"----conferenceClientDidDisconnect-----");
    
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),dispatch_get_main_queue(), ^{
        [weakSelf reset];
    });
    
}

- (void)conferenceClient:(OWTConferenceClient *)client didAddStream:(OWTRemoteStream *)stream {
    NSLog(@"----conferenceClient didAddStream-----%@",stream.attributes);
    
    OWTConferenceParticipant *participant = self.participantDict[stream.origin];
    if(participant) {
        __weak typeof(self) weakSelf = self;
        [self subscribeStream:stream complete:^(OWTConferenceSubscription *sub, NSError *error) {
            if(error) {
                return;
            }
            [weakSelf subscribeSuccess:sub stream:stream participant:participant];
        }];
    }
}

- (void)conferenceClient:(OWTConferenceClient *)client didAddParticipant:(OWTConferenceParticipant *)user {
    NSLog(@"----conferenceClient didAddParticipant-----%@-->%@",user.userId,user.participantId);
    self.participantDict[user.participantId] = user;
}

- (void)conferenceClient:(OWTConferenceClient *)client didReceiveMessage:(NSString *)message from:(NSString *)senderId to:(NSString *)targetType {
//    
//    if(!self.receiveMessage) {
//        return;
//    }
    NSLog(@"----conferenceClient didReceiveMessage-----");
    
    NSLog(@"message-->%@ from->%@ to->%@",message,senderId,targetType);
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:NSJSONReadingMutableContainers
                                                            error:&err];
    if(err) {
        WKLogError(@"接受到的视频消息有误！%@",err);
        return;
    }
    NSString *cmd = dic[@"cmd"];
    if([cmd isEqualToString:@"enableVideo"]) {
        
    }
}


#pragma mark -- OWTRemoteStreamDelegate

- (void)streamDidEnd:(OWTRemoteStream *)stream {
    NSLog(@"########streamDidEnd########");
}

- (void)streamDidUpdate:(OWTRemoteStream *)stream {
    NSLog(@"########streamDidUpdate########");
}

- (void)streamDidMute:(OWTRemoteStream *)stream trackKind:(OWTTrackKind)kind {
    NSLog(@"########streamDidMute########");
    if(kind != OWTTrackKindVideo) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    lim_dispatch_main_async_safe(^{
        [weakSelf muteVideo:stream.origin mute:YES];
    });
    
}

-(void) muteVideo:(NSString*)participantID mute:(BOOL)mute {
    OWTConferenceParticipant *participant = self.participantDict[participantID];
    if(participant) {
       WKRTCStreamView *streamView = [WKRTCManager.shared.rtcChatView streamView:participant.userId];
        streamView.openVideo = !mute;
    }
}

- (void)streamDidUnmute:(OWTRemoteStream *)stream trackKind:(OWTTrackKind)kind {
    NSLog(@"########streamDidUnmute########");
    if(kind != OWTTrackKindVideo) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    lim_dispatch_main_async_safe(^{
        [weakSelf muteVideo:stream.origin mute:NO];
    });
}


#pragma mark -- OWTP2PPublicationDelegate

- (void)publicationDidEnd:(OWTP2PPublication*)publication {
    NSLog(@"########publicationDidEnd########");
}

#pragma mark -- OWTConferenceParticipantDelegate

- (void)participantDidLeave:(OWTConferenceParticipant *)participant {
    NSLog(@"########participantDidLeave########");
    lim_dispatch_main_async_safe(^{
        [WKRTCManager.shared participantLeave:participant.userId reason:@"已挂断"];
    });
    
}

#pragma mark -- OWTConferencePublicationDelegate

- (void)publicationDidMute:(OWTConferencePublication *)publication trackKind:(OWTTrackKind)kind {
    NSLog(@"########publicationDidMute########");
}

- (void)publicationDidUnmute:(OWTConferencePublication *)publication trackKind:(OWTTrackKind)kind {
    NSLog(@"########publicationDidUnmute########");
}

- (void)publicationDidError:(OWTConferencePublication *)publication errorInfo:(NSError *)error {
    NSLog(@"########publicationDidError########");
}


@synthesize allowedRemoteIds;
@synthesize receiveMessage;


@synthesize delegate;

@end
