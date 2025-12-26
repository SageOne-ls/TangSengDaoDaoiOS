//
//  WKRTCP2PSignalingManager.m
//  WuKongRTC
//
//  Created by tt on 2022/9/15.
//

#import "WKRTCP2PSignalingManager.h"

#import <WuKongBase/WuKongBase.h>
#import "WKVideoCallSystemContent.h"

@implementation WKRTCP2PSignalingManager


static WKRTCP2PSignalingManager *_instance;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCP2PSignalingManager *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}


- (AnyPromise*)sendInvite:(NSString *)to callType:(WKRTCCallType)callType{
    
   return [WKAPIClient.sharedClient POST:@"rtc/p2p/invoke" parameters:@{
        @"to_uid": to,
        @"call_type": @(callType),
    }];
    
}

- (AnyPromise*)sendRefuse:(NSString *)to callType:(WKRTCCallType)callType{
    return [WKAPIClient.sharedClient POST:@"rtc/p2p/refuse" parameters:@{
         @"uid": to,
         @"call_type": @(callType),
     }];
//    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"拒绝通话" second:@(0) type:WK_VIDEOCALL_REFUSE];
//    [[WKSDK shared].chatManager sendMessage:content channel:[WKChannel personWithChannelID:to]];
}

- (AnyPromise*)sendAccepted:(NSString *)to callType:(WKRTCCallType)callType{
    return [WKAPIClient.sharedClient POST:@"rtc/p2p/accept" parameters:@{
         @"from_uid": to,
         @"call_type": @(callType),
     }];
//    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"接受通话" second:@(0) type:WK_VIDEOCALL_ACCEPT];
//    [[WKSDK shared].chatManager sendMessage:content channel:[WKChannel personWithChannelID:to]];
}


- (AnyPromise*)sendHangup:(NSString *)to time:(NSInteger)second callType:(WKRTCCallType)callType isCaller:(BOOL)isCaller{
    return [WKAPIClient.sharedClient POST:@"rtc/p2p/hangup" parameters:@{
         @"uid": to,
         @"second": @(second),
         @"call_type": @(callType),
         @"is_caller":@(isCaller?1:0),
     }];
//    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"挂断通话" second:@(second) type:WK_VIDEOCALL_HANGUP];
//    [[WKSDK shared].chatManager sendMessage:content channel:[WKChannel personWithChannelID:to]];
}

-(AnyPromise*) sendCancel:(NSString*)to callType:(WKRTCCallType)callType{
    return [WKAPIClient.sharedClient POST:@"rtc/p2p/cancel" parameters:@{
         @"uid": to,
         @"call_type": @(callType),
     }];
//    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"取消通话" second:@(0) type:WK_VIDEOCALL_CANCEL];
//    [[WKSDK shared].chatManager sendMessage:content channel:[WKChannel personWithChannelID:to]];
}

- (void)sendSwitchToVoice:(NSString *)to {
    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"切换到语音" second:@(0) type:WK_VIDEOCALL_SWITCH];
    WKMessage *messageModel = [[WKSDK shared].chatManager contentToMessage:content channel:[WKChannel personWithChannelID:to] fromUid:nil];
     messageModel.header.noPersist = YES;
    messageModel.header.showUnread = NO;
    [[WKSDK shared].chatManager sendMessage:messageModel];
}

- (void)sendSwitchToVideo:(NSString *)to {
    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"切换视频" second:@(0) type:WK_VIDEOCALL_SWITCH_TO_VIDEO];
    WKMessage *messageModel = [[WKSDK shared].chatManager contentToMessage:content channel:[WKChannel personWithChannelID:to] fromUid:nil];
     messageModel.header.noPersist = YES;
    messageModel.header.showUnread = NO;
    [[WKSDK shared].chatManager sendMessage:messageModel];
}

- (void)sendSwitchToVideoReply:(NSString *)to agree:(BOOL)agree {
    WKVideoCallSystemContent *content = [WKVideoCallSystemContent initWithContent:@"切换视频回应" second:@(0) type:WK_VIDEOCALL_SWITCH_TO_VIDEO_REPLY];
    content.agree = agree;
    WKMessage *messageModel = [[WKSDK shared].chatManager contentToMessage:content channel:[WKChannel personWithChannelID:to] fromUid:nil];
     messageModel.header.noPersist = YES;
    messageModel.header.showUnread = NO;
    [[WKSDK shared].chatManager sendMessage:messageModel];
}

@end
