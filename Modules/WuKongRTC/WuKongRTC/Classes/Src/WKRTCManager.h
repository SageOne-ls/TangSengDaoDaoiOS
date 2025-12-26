//
//  WKRTCManager.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>
#import "WKRTCParticipant.h"
#import "WKRTCConstants.h"
#import "WKRTCOption.h"
#import "WKRTCChatViewProtocol.h"
#import <WebRTC/WebRTC.h>
@class WKRTCManager;
NS_ASSUME_NONNULL_BEGIN


@protocol WKRTCManagerDelegate <NSObject>


// 邀请参与rtc的用户
-(void) rtcManager:(WKRTCManager*)manager didInviteAtChannel:(WKChannel*)channel data:(NSDictionary * __nullable)dataDict complete:(void(^)(NSArray<NSString*>*))complete;

@end

@interface WKRTCManager : NSObject

+ (WKRTCManager *)shared;


@property(nonatomic,strong) WKRTCOption *options;

@property(nonatomic,weak) id<WKRTCManagerDelegate> delegate;

@property(nonatomic,assign) BOOL isCallCreater;

@property(nonatomic,assign) WKRTCCallType callType;

@property(nonatomic,strong,nullable) WKChannel *currentChannel;

@property(nonatomic,assign,readonly) BOOL isCalling; // 是否正在call

@property(nonatomic,strong,nullable) id<WKRTCChatViewProtocol> rtcChatView; // rtc ui



-(void) call:(WKChannel*)channel callType:(WKRTCCallType)callType;


@property(nonatomic,copy,readonly) void(^getParticipant)(NSString *uid,ParticipantCallback callback); // 获取用户信息的block

-(void) participantLeave:(NSString*)uid reason:(NSString* __nullable)reason; // 参与者离开

-(void) presentViewController:(UIViewController*)vc;

@end

NS_ASSUME_NONNULL_END
