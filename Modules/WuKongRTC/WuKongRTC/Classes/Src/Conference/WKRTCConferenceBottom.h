//
//  WKRTCConferenceBottom.h
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRTCConferenceBottom : UIView

@property(nonatomic,copy) void(^onHangup)(void);

@property(nonatomic,copy) void(^onArrow)(void);

@property(nonatomic,copy) void(^onCameraSwitch)(BOOL on); // 语音/视频切换


@property(nonatomic,copy) void(^onHandsFree)(BOOL on); // 免提开关

@property(nonatomic,copy) void(^onMute)(BOOL on); // 静音

@property(nonatomic,assign) BOOL changeToSmall; // 改变成小模式


@end

NS_ASSUME_NONNULL_END
