//
//  WKTP2PSignalingChannel.m
//  WuKongRTC
//
//  Created by tt on 2021/5/10.
//

#import "WKTP2PSignalingChannel.h"
#import <WuKongBase/WuKongBase.h>
#import "WKRTCDataContent.h"
#import "WKVideoCallSystemContent.h"
#import "WKRTCManager.h"
#import "WKRTCStreamManager.h"
#import <WuKongBase/WuKongBase.h>
typedef  void(^onSendSucccess)(void);

@interface WKTP2PSignalingChannel ()<WKChatManagerDelegate>

@property(nonatomic,assign) uint32_t currentMaxClientSeq;

@property(nonatomic,strong) NSRecursiveLock *lock;
@property(nonatomic,strong) NSMutableDictionary<NSString*,onSendSucccess> *cacheMessageDict;

@end

@implementation WKTP2PSignalingChannel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.currentMaxClientSeq = 1000000;
        [[WKSDK shared].chatManager addDelegate:self];
    }
    return self;
}

- (void)connect:(NSString*)token
      onSuccess:(void (^)(NSString*))onSuccess
      onFailure:(void (^)(NSError*))onFailure {
    NSLog(@"connect------>%@",token);
    
//    self.currentMaxClientSeq = (uint32_t)[[WKSDK shared].chatManager getMessageMaxClientSeq];
//    if(self.currentMaxClientSeq<=0) {
//        onFailure([NSError errorWithDomain:@"查询本地序列号失败！" code:0 userInfo:nil]);
//        return;
//    }
//    self.currentMaxClientSeq += 10000; // 发起视频后，用数据库现在的最大clientSeq增加10000 以防本机发送消息递增的clientSeq覆盖rtc的clientSeq（理论上在视频通话不会在发消息了，如果一边视频通话一边发消息，超过10000条这里可能就有BUG了！！）
    onSuccess(@"");
    
}

- (void)sendMessage:(NSString*)message
                 to:(NSString*)targetId
          onSuccess:(void (^)())onSuccess
          onFailure:(void (^)(NSError*))onFailure {
  //  NSLog(@"sendMessage----->%@ targetId-->%@",message,targetId);
   
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf.lock lock];
        weakSelf.currentMaxClientSeq ++;
        weakSelf.cacheMessageDict[[NSString stringWithFormat:@"%u",weakSelf.currentMaxClientSeq]] = onSuccess;
//        NSLog(@"currentMaxClientSeq-------->%d",weakSelf.currentMaxClientSeq);
        [weakSelf.lock unlock];
        
        WKMessage *messageModel = [[WKSDK shared].chatManager contentToMessage:[WKRTCDataContent data:message] channel:[WKChannel personWithChannelID:targetId] fromUid:nil];
         messageModel.header.noPersist = YES;
        messageModel.header.showUnread = NO;
        messageModel.clientSeq = weakSelf.currentMaxClientSeq;
        
        [[WKSDK shared].chatManager sendMessage:messageModel addRetryQueue:false];
    });
   
   
    
//    NSLog(@"-----------------------send--message-start-----------------------");
//    NSLog(@"%@",message);
//    NSLog(@"-----------------------send--message-end-----------------------");
    
    if([message containsString:@"\"type\":\"answer\""] && [message containsString:@"\"sdp\":"] ) {
        NSLog(@"#####sendMessage-answer");
        // 当发送SDP消息时才推流 安卓设备提前推流可能会导致set remoteSDP失败
//        [[WKRTCClient shared] p2pRequestPublishLocalStream];
        
//        if(WKRTCManager.shared.isCallCreater && WKRTCManager.shared.currentChannel && WKRTCManager.shared.currentChannel.channelType == WK_PERSON) {
//            NSLog(@"signaling publishStream");
//            lim_dispatch_main_async_safe(^{
//                [WKRTCStreamManager.shared publishLocalStream];
//            });
//        }
        
    }
    
    
}

- (void)disconnectWithOnSuccess:(void (^)())onSuccess
                      onFailure:(void (^)(NSError*))onFailure {
    NSLog(@"disconnectWithOnSuccess------>");
    if(onSuccess) {
        onSuccess();
    }
   
}

//- (void)sendInvite:(NSString *)to {
//    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"发起通话" second:@(0) type:WK_VIDEOCALL_RECEIVED];
//    WKMessage *messageModel = [[WKSDK shared].chatManager contentToMessage:content channel:[WKChannel personWithChannelID:to] fromUid:nil];
//    messageModel.header.noPersist = YES;
//    messageModel.header.showUnread = NO;
//    [[WKSDK shared].chatManager sendMessage:messageModel];
//}

- (void)sendRefuse:(NSString *)to {
    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"拒绝通话" second:@(0) type:WK_VIDEOCALL_REFUSE];
    [[WKSDK shared].chatManager sendMessage:content channel:[WKChannel personWithChannelID:to]];
}

- (void)sendAccepted:(NSString *)to {
    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"接受通话" second:@(0) type:WK_VIDEOCALL_ACCEPT];
    [[WKSDK shared].chatManager sendMessage:content channel:[WKChannel personWithChannelID:to]];
}


- (void)sendHangup:(NSString *)to time:(int)second {
    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"挂断通话" second:@(second) type:WK_VIDEOCALL_HANGUP];
    [[WKSDK shared].chatManager sendMessage:content channel:[WKChannel personWithChannelID:to]];
}

- (NSMutableDictionary *)cacheMessageDict {
    if(!_cacheMessageDict) {
        _cacheMessageDict = [[NSMutableDictionary alloc] init];
    }
    return _cacheMessageDict;
}

- (NSRecursiveLock *)lock {
    if(!_lock) {
        _lock = [[NSRecursiveLock alloc] init];
    }
    return _lock;
}

#pragma mark -- WKChatManagerDelegate


- (void)onRecvMessages:(WKMessage *)message left:(NSInteger)left {
    if(message.contentType == WK_VIDEOCALL_DATA) {
        WKRTCDataContent *content = (WKRTCDataContent*)message.content;
        NSLog(@"-----------------------message-start-----------------------");
        NSLog(@"%@",content.data);
        NSLog(@"-----------------------message-end-----------------------");
        
        [self.delegate channel:self didReceiveMessage:content.data from:message.channel.channelId];
       
    }
}

- (void)onSendack:(WKSendackPacket *)sendackPacket left:(NSInteger)left {
    
    [self.lock lock];
    NSString *clientSeqKey = [NSString stringWithFormat:@"%u",sendackPacket.clientSeq];
    onSendSucccess successBlock = [self.cacheMessageDict objectForKey:clientSeqKey];
    [self.lock unlock];
    if(successBlock) {
        NSLog(@"clientSeqKey--->%@",clientSeqKey);
        successBlock();
        [self.lock lock];
        [self.cacheMessageDict removeObjectForKey:clientSeqKey];
        [self.lock unlock];
    }
}

@synthesize delegate;

@end
