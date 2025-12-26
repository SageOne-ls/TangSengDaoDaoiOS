//
//  WKRTCActionButton.h
//  WuKongRTC
//
//  Created by tt on 2021/5/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRTCActionButton : UIView

-(instancetype) initWithIcon:(NSString * __nullable)icon onIcon:(NSString * __nullable)onicon title:(NSString*)title;

@property(nonatomic,assign) BOOL on;

@property(nonatomic,assign) BOOL changeToSmall;

@property(nonatomic,strong) UILabel *titleLbl;
@property(nonatomic,strong) UIImageView *iconImgView;

@property(nonatomic,copy) void(^onSwitch)(BOOL on);

@end


// 静音
@interface WKMuteActionButton : WKRTCActionButton

@end

// 免提
@interface WKHandsFreeActionButton : WKRTCActionButton

@end

// 视频/语音切换
@interface WKCameraSwitcActionButton : WKRTCActionButton

@end

// 前/后摄像头切换
@interface WKCameraToggleActionButton : WKRTCActionButton

@end

// 应答
@interface WKAnswerActionButton : WKRTCActionButton

@end

// 挂断
@interface WKHangupActionButton : WKRTCActionButton

@property(nonatomic,assign) BOOL style2; // 样式2

@end

NS_ASSUME_NONNULL_END
