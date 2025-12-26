//
//  WKParticipant.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    WKRTCParticipantRoleCommon, // 普通
    WKRTCParticipantRoleInviter, // 创建者
} WKRTCParticipantRole;

@interface WKRTCParticipant : NSObject

-(instancetype) initWithUID:(NSString*)uid;

@property(nonatomic,copy) NSString *uid; // 用户uid

@property(nonatomic,copy) NSString *name; // 用户名称

@property(nonatomic,copy) NSURL *avatar; // 头像

@property(nonatomic,assign) WKRTCParticipantRole role; // 角色

@end

NS_ASSUME_NONNULL_END
