//
//  WKRTCStreamManager.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import <WebRTC/WebRTC.h>
#import <OWT/OWT.h>
#import "WKRTCStream.h"
#import "WKRTCConstants.h"
#import <WuKongIMSDK/WuKongIMSDK.h>
@class WKRTCStreamManager;
NS_ASSUME_NONNULL_BEGIN

@protocol WKRTCStreamManagerDelegate <NSObject>

@optional

// stream发送更新
-(void) rtcStreamManager:(WKRTCStreamManager*)manager didAddStream:(WKRTCStream*)stream;

@end

@interface WKRTCStreamManager : NSObject

+ (WKRTCStreamManager *)shared;

@property(nonatomic,weak) id<WKRTCStreamManagerDelegate> delegate;

@property(nonatomic, strong,nullable) WKRTCStream* localStream; // 本地stream

@property(nonatomic,assign) BOOL joinRoomed; // 是否已加入房间

// 获取指定用户的流
-(WKRTCStream*) streamWidthUID:(NSString*)uid;

-(void) addOrUpdateStream:(WKRTCStream*)stream;

/**
  创建房间（发起通话的执行）
 */
-(void) createRoom:(WKChannel*)channel participants:(NSArray<WKRTCParticipant*>*)participants callType:(WKRTCCallType)callType complete:(void(^)(NSString *roomID,NSString *token,NSError *error))complete;

/**
  加入房间（接受通话的执行）
 */
-(void) joinRoom:(NSString*)roomID complete:(void(^)(NSString *token,NSError *error))complete;
/**
  发布流
 */
-(void) publish:(WKRTCStream*)stream;

/**
  推送本地流
 */
-(void) publishLocalStream;
/**
  订阅流 订阅后收到流将会通过WKRTCStreamManagerDelegate通知
 */
-(void) subscribe:(NSString*)token complete:(void(^)(NSError* __nullable error))complete;

/**
  离开房间
 */
-(void) leaveRoom:(void(^)(NSError * __nullable error))complete;


// 所有流
-(NSArray<WKRTCStream*>*) streamAll;


-(void) reset;

@end

NS_ASSUME_NONNULL_END
