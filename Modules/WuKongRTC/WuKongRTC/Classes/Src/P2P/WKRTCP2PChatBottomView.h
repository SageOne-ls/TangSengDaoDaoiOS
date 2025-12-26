//
//  WKRTCP2PChatBottomView.h
//  WuKongRTC
//
//  Created by tt on 2022/10/4.
//

#import <UIKit/UIKit.h>
#import "WKRTCConstants.h"
#import "WKRTCConst.h"
#import "WKRTCActionButton.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCP2PChatBottomView : UIView

-(instancetype) initWithFrame:(CGRect)frame status:(WKRTCStatus)status viewType:(WKRTCViewType)viewType callType:(WKRTCCallType)callType;

@property(nonatomic,assign) WKRTCStatus status;
@property(nonatomic,assign) WKRTCViewType viewType;
@property(nonatomic,assign) WKRTCCallType callType;

@property(nonatomic,strong) WKCameraSwitcActionButton *cameraSwitchBtn; // 视频/语音切换
@property(nonatomic,strong) WKHangupActionButton *hangupBtn; // 挂断

@property(nonatomic,strong) WKAnswerActionButton *answerBtn; // 应答

@property(nonatomic,strong) WKCameraToggleActionButton *cameraToggleBtn; // 前/后摄像头切换

@property(nonatomic,strong) WKHandsFreeActionButton *handsFreeBtn; // 免提

@property(nonatomic,strong) WKMuteActionButton *muteBtn; // 静音

@property(nonatomic,copy) void(^onHangup)(void); // 挂断

@property(nonatomic,copy) void(^onAnswer)(void); // 应答

@property(nonatomic,copy) void(^onHandsFree)(BOOL on); // 免提开关

@property(nonatomic,copy) void(^onMute)(BOOL on); // 静音

@property(nonatomic,copy) void(^onCameraToggle)(BOOL on); // 前/后摄像头切换
@property(nonatomic,copy) void(^onCameraSwitch)(BOOL on); //


@end

NS_ASSUME_NONNULL_END
