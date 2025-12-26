//
//  WKRTCConferenceResponseView.h
//  WuKongRTC
//
//  Created by tt on 2022/9/15.
//

#import <UIKit/UIKit.h>
#import "WKRTCParticipant.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCConferenceResponseView : UIView


@property(nonatomic,strong) NSArray<WKRTCParticipant*> *participants; // 参与者uid集合

@property(nonatomic,copy,nullable) void(^onHangup)(void); // 挂断
@property(nonatomic,copy,nullable) void(^onAnswer)(void); // 接听

@end

NS_ASSUME_NONNULL_END
