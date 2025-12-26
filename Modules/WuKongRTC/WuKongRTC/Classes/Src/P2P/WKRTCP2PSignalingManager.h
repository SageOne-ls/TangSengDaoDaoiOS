//
//  WKRTCP2PSignalingManager.h
//  WuKongRTC
//
//  Created by tt on 2022/9/15.
//

#import <Foundation/Foundation.h>
#import "WKRTCConstants.h"
#import <PromiseKit/PromiseKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCP2PSignalingManager : NSObject

+ (WKRTCP2PSignalingManager *)shared;

// 发送邀请通话消息
- (AnyPromise*) sendInvite:(NSString*)to callType:(WKRTCCallType)callType;

// 发送已接受邀请消息
- (AnyPromise*)sendAccepted:(NSString *)to callType:(WKRTCCallType)callType;

// 发送拒绝通话消息(还没建立通话)
-(AnyPromise*) sendRefuse:(NSString*)to callType:(WKRTCCallType)callType;

// 挂断通话（已建立通话）
// @param second 通话时长
-(AnyPromise*) sendHangup:(NSString*)to time:(NSInteger)second callType:(WKRTCCallType)callType isCaller:(BOOL)isCaller;

// 通话取消
-(AnyPromise*) sendCancel:(NSString*)to callType:(WKRTCCallType)callType;

// 发送切换到视频的消息
-(void) sendSwitchToVideo:(NSString*)to;
// 发送切换到语音的消息
-(void) sendSwitchToVoice:(NSString*)to;

// 
-(void) sendSwitchToVideoReply:(NSString*)to agree:(BOOL)agree;
@end

NS_ASSUME_NONNULL_END
