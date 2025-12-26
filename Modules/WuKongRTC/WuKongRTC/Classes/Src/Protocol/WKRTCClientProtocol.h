//
//  WKRTCClientProtocol.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCStream.h"
#import "WKRTCConstants.h"
@protocol WKRTCClientProtocol;
NS_ASSUME_NONNULL_BEGIN

@protocol  WKRTCClientProtocolDelegate<NSObject>

// 客户端结束
-(void) rtcClientDidEnd:(id<WKRTCClientProtocol>)rtcClient to:(NSString*)to;

@end

@protocol WKRTCClientProtocol <NSObject>

@property(nonatomic,strong) NSMutableArray<NSString*> *allowedRemoteIds;

@property(nonatomic,assign) BOOL receiveMessage;

@property(nonatomic,weak) id<WKRTCClientProtocolDelegate> delegate;

// 设置是否允许收rtc消息（解决同一个号多端收到rtc的问题）
-(void) setAllowReceiveMessage:(BOOL)receiveMessage;

// 连接
- (void)connect:(NSString*)token
      onSuccess:(nullable void (^)(NSString*))onSuccess
      onFailure:(nullable void (^)(NSError*))onFailure;

// 断开
- (void)disconnectWithOnSuccess:(nullable void (^)(void))onSuccess
                      onFailure:(nullable void (^)(NSError*))onFailure;


// 发布stream
-(void)publishStream:(WKRTCStream*)stream to:(NSString* __nullable)to;



@end

NS_ASSUME_NONNULL_END
