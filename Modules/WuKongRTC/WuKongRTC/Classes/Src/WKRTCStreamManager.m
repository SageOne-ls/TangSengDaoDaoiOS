//
//  WKRTCStreamManager.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCStreamManager.h"
#import "WKRTCStream.h"
#import "WKRTCManager.h"
#import "WKRTCClientManager.h"
#import "WKRTCConferenceClientProtocol.h"
#import "WKRTCP2PSignalingManager.h"
#import "WKRTCRoomUtil.h"
#import "WKRTCAPIClient.h"

@interface WKRTCStreamManager ()

@property(nonatomic,strong) NSMutableDictionary *streamDict;

@property(nonatomic,copy,nullable) NSString *currentRoomID;

@property(nonatomic,assign) BOOL localStreamPublished;



@end

@implementation WKRTCStreamManager

static WKRTCStreamManager *_instance;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCStreamManager *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

- (NSMutableDictionary *)streamDict {
    if(!_streamDict) {
        _streamDict = [NSMutableDictionary dictionary];
    }
    return _streamDict;
}

- (WKRTCStream *)localStream {
    if(!_localStream) {
       _localStream = [WKRTCManager.shared.options.provider getLocalStream];
    }
    return _localStream;
}

-(void) addOrUpdateStream:(WKRTCStream*)stream {
    self.streamDict[stream.uid] = stream;
    
    lim_dispatch_main_async_safe(^{
        if(self.delegate &&[self.delegate respondsToSelector:@selector(rtcStreamManager:didAddStream:)]) {
            [self.delegate rtcStreamManager:self didAddStream:stream];
        };
    });
   
}

- (void)createRoom:(WKChannel*)channel participants:(NSArray<WKRTCParticipant *> *)participants callType:(WKRTCCallType)callType complete:(void (^)(NSString * roomID, NSString * token, NSError * error))complete {
    WKRTCMode mode = WKRTCModeP2P;
    if(channel.channelType == WK_GROUP) {
        mode = WKRTCModeConference;
    }
    
    id<WKRTCClientProtocol> client = [[WKRTCClientManager shared] getClient:mode];
    if(mode == WKRTCModeP2P) {
        client.allowedRemoteIds = @[channel.channelId,WKRTCManager.shared.options.uid].mutableCopy;
    }
    __weak typeof(self) weakSelf = self;
    if(mode == WKRTCModeP2P) {
        NSString *token  = @"no need token";
        NSString *roomID = [WKRTCRoomUtil genPersonRoomID:WKRTCManager.shared.options.uid toUID:channel.channelId];
        self.currentRoomID = roomID;
        UIView *topView = WKNavigationManager.shared.topViewController.view;
        self.joinRoomed = true;
        [client connect:token onSuccess:^(NSString * msg) {
            [WKRTCP2PSignalingManager.shared sendInvite:channel.channelId callType:callType].catch(^(NSError *error){
                [topView showHUDWithHide:error.domain];
            });
//            [weakSelf publishLocalStream]; // TODO: 不能在此推流，对方容易收不到流
            lim_dispatch_main_async_safe(^{
                if(complete) {
                    complete(roomID,token,nil);
                }
            });
        } onFailure:^(NSError * err) {
            WKLogError(@"连接RTC信令服务器失败！->%@",err);
            lim_dispatch_main_async_safe(^{
                if(complete) {
                    complete(nil,nil,err);
                }
            });
           
        }];
    }else {
       
        self.joinRoomed = true;
        id<WKRTCConferenceClientProtocol> conferenceClient = ( id<WKRTCConferenceClientProtocol>)client;
       
        NSMutableArray<NSString*> *participantIDs = [NSMutableArray array];
        if(participants && participants.count>0) {
            for (WKRTCParticipant *participant in participants) {
                [participantIDs addObject:participant.uid];
            }
        }
        
        [conferenceClient createConference:participantIDs complete:^(NSString * roomID,NSString * token, NSError * error) {
            lim_dispatch_main_async_safe(^{
                if(error) {
                    if(complete) {
                        complete(nil,nil,error);
                    }
                    return;
                }
                weakSelf.currentRoomID = roomID;
                if(complete) {
                    complete(roomID,token,nil);
                }
            });
        }];
    }
}

-(void) joinRoom:(NSString*)roomID complete:(void(^)(NSString *token,NSError *error))complete{
    self.currentRoomID = roomID;
    self.joinRoomed = true;
    WKRTCMode mode = WKRTCModeConference;
    if([WKRTCRoomUtil isPersonRoom:roomID]) {
        mode = WKRTCModeP2P;
    }
    
    id<WKRTCClientProtocol> client = [[WKRTCClientManager shared] getClient:mode];
    if(mode == WKRTCModeP2P) {
        client.allowedRemoteIds = [WKRTCRoomUtil getParticipantFromRoom:roomID].mutableCopy;
    }
    
    __weak typeof(client) weakClient = client;
    [WKRTCAPIClient.shared getToken:roomID complete:^(NSString * _Nonnull token, NSError * _Nonnull error) {
        if(error) {
            if(complete) {
                complete(nil,error);
            }
            return;
        }
        if(mode == WKRTCModeP2P) { // p2p
            [weakClient connect:token onSuccess:^(NSString * msg) {
//                [weakSelf publishLocalStream]; // 推流
                
                
            } onFailure:^(NSError * err) {
                WKLogError(@"连接RTC信令服务器失败！->%@",err);
            }];
            if(complete) {
                complete(token,nil);
            }
        }else{ // 会议
            if(complete) {
                complete(token,nil);
            }
        }
       
        
    }];
}
-(void) leaveRoom:(void(^)(NSError *error))complete {

    NSString *roomID = self.currentRoomID;
    WKRTCMode mode = WKRTCModeConference;
    if([WKRTCRoomUtil isPersonRoom:roomID]) {
        mode = WKRTCModeP2P;
    }
    
    if(mode == WKRTCModeP2P) {
        id<WKRTCClientProtocol> client = [[WKRTCClientManager shared] getClient:mode];
    
        [client disconnectWithOnSuccess:^{
            
        } onFailure:^(NSError * err) {
            
        }];
        
        complete(nil);
        return;
    }
    id<WKRTCConferenceClientProtocol> client = (id<WKRTCConferenceClientProtocol>)[[WKRTCClientManager shared] getClient:mode];
    
    [client leaveConference:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(complete) {
                complete(error);
            }
        });
    }];
}

- (void)publish:(WKRTCStream *)stream {
    if(!self.currentRoomID) {
        return;
    }
    WKRTCMode mode = WKRTCModeConference;
    NSString *to;
    if([WKRTCRoomUtil isPersonRoom:self.currentRoomID]) {
        mode = WKRTCModeP2P;
        to = [WKRTCRoomUtil getToFromRoomID:self.currentRoomID];
        NSLog(@"to——————>%@ ---->%@",to,WKRTCManager.shared.options.uid);
    }
    id<WKRTCClientProtocol> client = [[WKRTCClientManager shared] getClient:mode];
    
    [client publishStream:stream to:to];
    
}

- (void)subscribe:(NSString *)token complete:(void(^)(NSError *error))complete{
    if(!self.currentRoomID) {
        if(complete) {
            complete(nil);
        }
        return;
    }
    
    WKRTCMode mode = WKRTCModeConference;
    if([WKRTCRoomUtil isPersonRoom:self.currentRoomID]) { // 个人房间不需要订阅
        mode = WKRTCModeP2P;
        if(complete) {
            complete(nil);
        }
        return;
    }
   
    id<WKRTCConferenceClientProtocol> client = (id<WKRTCConferenceClientProtocol>)[[WKRTCClientManager shared] getClient:mode];
    [client subscribe:token complete:^(NSError * err) {
        if(complete) {
            complete(err);
        }
    }];
}

-(void) publishLocalStream {
    if(self.localStreamPublished) {
        return;
    }
    self.localStreamPublished = true;
    [self publish:self.localStream];
}

- (WKRTCStream *)streamWidthUID:(NSString *)uid {
    return self.streamDict[uid];
}

-(NSArray<WKRTCStream*>*) streamAll {
    NSMutableArray<WKRTCStream*> *streams = [NSMutableArray arrayWithArray:self.streamDict.allValues];
    if(_localStream) {
        [streams addObject:_localStream]; // 这里不能用self.localStream
    }
    
    return streams;
}

-(void) stopAllStream {
    [self.localStream stop];
    self.localStream = nil;
    for (WKRTCStream *stream in self.streamDict.allValues) {
        [stream stop];
    }
}

- (void)reset {
    self.joinRoomed = false;
    self.localStreamPublished = false;
    [self stopAllStream];
    [self.streamDict removeAllObjects];
    self.currentRoomID = nil;
}

@end
