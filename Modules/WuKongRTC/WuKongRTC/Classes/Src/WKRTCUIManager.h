//
//  WKRTCUIManager.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCParticipant.h"
#import "WKRTCChatViewProtocol.h"
#import "WKRTCConstants.h"
#import "WKRTCConst.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCUIManager : NSObject

+ (WKRTCUIManager *)shared;

-(id<WKRTCChatViewProtocol>) createChatView:(NSArray<WKRTCParticipant*>*)participants mode:(WKRTCMode)mode viewType:(WKRTCViewType)viewType callType:(WKRTCCallType)type;

@end

NS_ASSUME_NONNULL_END
