//
//  WKRTCConferenceNavigation.h
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRTCConferenceNavigation : UIView

@property(nonatomic,strong) UILabel *timeLbl;

@property(nonatomic,copy) void(^onMin)(void);
@property(nonatomic,copy) void(^onAdd)(void);

@end

NS_ASSUME_NONNULL_END
