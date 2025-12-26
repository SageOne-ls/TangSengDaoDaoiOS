//
//  WKRTCConferenceView.h
//  WuKongRTC
//
//  Created by tt on 2022/9/15.
//

#import <Foundation/Foundation.h>
#import "WKRTCChatViewProtocol.h"
#import "WKRTCConst.h"
#import "WKRTCParticipant.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCConferenceView : UIView<WKRTCChatViewProtocol>

+(WKRTCConferenceView*) participants:(NSArray<WKRTCParticipant*>*)participants viewType:(WKRTCViewType)viewType;

@end

NS_ASSUME_NONNULL_END
