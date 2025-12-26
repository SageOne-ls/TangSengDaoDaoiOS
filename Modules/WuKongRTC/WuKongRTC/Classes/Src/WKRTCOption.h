//
//  WKRTCOption.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCProviderProtocol.h"
#import "WKRTCParticipant.h"
#import "WKRTCConstants.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCOption : NSObject


@property(nonatomic,copy) NSString *uid; // 当前用户uid

@property(nonatomic,strong) UIImage *defaultAvatar; // 默认头像

@property(nonatomic,assign) NSTimeInterval joinRoomTimeout; // 加入房间超时时间

@property(nonatomic,assign) NSTimeInterval p2pCallTimeout; // 呼叫超时

@property(nonatomic,assign) NSTimeInterval videoOtherUIHideInterval; // 视频其他UI隐藏时间间隔

@property(nonatomic,strong) id<WKRTCProviderProtocol> provider;

@property(nonatomic,copy) void(^getParticipant)(NSString *uid,ParticipantCallback callback); // 获取用户信息的block



@end

NS_ASSUME_NONNULL_END
