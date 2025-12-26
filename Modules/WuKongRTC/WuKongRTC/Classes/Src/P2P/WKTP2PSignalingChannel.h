//
//  WKTP2PSignalingChannel.h
//  WuKongRTC
//
//  Created by tt on 2021/5/10.
//

#import <Foundation/Foundation.h>
#import <OWT/OWT.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKTP2PSignalingChannel : NSObject<OWTP2PSignalingChannelProtocol>

//
//// 发送邀请通话消息
//-(void) sendInvite:(NSString*)to;

// 发送已接受邀请消息
-(void) sendAccepted:(NSString*) to;

// 发送拒绝通话消息(还没建立通话)
-(void) sendRefuse:(NSString*)to;

// 挂断通话（已建立通话）
// @param second 通话时长
-(void) sendHangup:(NSString*)to time:(int)second;

@end

NS_ASSUME_NONNULL_END
