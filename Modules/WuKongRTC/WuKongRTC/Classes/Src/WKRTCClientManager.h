//
//  WKRTCClientManager.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCClientProtocol.h"
#import "WKRTCConstants.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCClientManager : NSObject


+ (WKRTCClientManager *)shared;

@property(nonatomic,weak) id<WKRTCClientProtocolDelegate> delegate;

-(id<WKRTCClientProtocol>) getClient:(WKRTCMode)mode;

@end

NS_ASSUME_NONNULL_END
