//
//  WKRTCAPIClient.h
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import <Foundation/Foundation.h>
#import "WKRTCModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCAPIClient : NSObject

+ (WKRTCAPIClient *)shared;

/**
 创建房间
 @param req 创建房间的请求参数
 */
-(void) createRoom:(WKCreateRoomReq*) req complete:(void(^)(WKCreateRoomResp *resp,NSError *error)) complete;

/**
  加入房间
 */

- (void)getToken:(NSString *)roomID complete:(void(^)(NSString *token,NSError *error))complete;

-(void) invoke:(NSString*)roomID uids:(NSArray<NSString*>*)uids complete:(void(^)(NSError * __nullable error))complete;

/**
  拒绝加入房间
 */
-(void) roomRefuse:(NSString*)roomID complete:(void(^)(NSError * __nullable error))complete;

/**
  已加入房间
 */
-(void) roomJoined:(NSString*)roomID complete:(void(^)(NSError * __nullable error))complete;

/**
  挂断房间
 */
-(void) roomHangup:(NSString*)roomID complete:(void(^)(NSError * __nullable error))complete;

@end

NS_ASSUME_NONNULL_END
