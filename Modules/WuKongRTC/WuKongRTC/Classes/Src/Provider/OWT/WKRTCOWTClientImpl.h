//
//  WKRTCOWTClientImpl.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCClientProtocol.h"
#import "WKRTCConferenceClientProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCOWTP2PClientImpl : NSObject<WKRTCClientProtocol>

+ (WKRTCOWTP2PClientImpl *)shared;

@end

@interface WKRTCOWTConferenceClientImpl : NSObject<WKRTCClientProtocol,WKRTCConferenceClientProtocol>

+ (WKRTCOWTConferenceClientImpl *)shared;

@end

NS_ASSUME_NONNULL_END
