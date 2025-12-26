//
//  WKP2PChatView.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <UIKit/UIKit.h>
#import "WKRTCChatViewProtocol.h"
#import "WKRTCConst.h"
#import "WKRTCConstants.h"
#import "WKRTCParticipant.h"
#import "WKRTCP2PChatBottomView.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKP2PChatView : UIView<WKRTCChatViewProtocol>

// ---------- 底部view ----------
@property(nonatomic,strong) WKRTCP2PChatBottomView *bottomView;

+(WKP2PChatView*) participants:(NSArray<WKRTCParticipant*>*)participants viewType:(WKRTCViewType)viewType callType:(WKRTCCallType)callType;

@end


NS_ASSUME_NONNULL_END
