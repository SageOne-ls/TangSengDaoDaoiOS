//
//  WKRTCChatViewProtocol.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCStreamView.h"
#import "WKRTCConst.h"
#import "WKRTCConstants.h"
NS_ASSUME_NONNULL_BEGIN

typedef void(^AddParticipantCallback)(NSArray<NSString*>*participantIDs);

@protocol WKRTCChatViewProtocol <NSObject>

@property(nonatomic,copy) void(^onAccepted)(void); // 接受rtc

@property(nonatomic,copy) void(^onHangup)(void); // 挂断

@property(nonatomic,copy) void(^onHandsFree)(BOOL on); // 免提开关

@property(nonatomic,copy) void(^onMute)(BOOL on); // 静音

@property(nonatomic,copy) void(^onSwitch)(void); // 视频/语音切换

@property(nonatomic,copy) void(^onSwitchCamera)(void); // 切换摄像头

@property(nonatomic,copy) void(^onAddParticipant)(AddParticipantCallback callback); // 添加参与者

@property(nonatomic,assign) BOOL handsFree; // 是否开启免提

@property(nonatomic,assign,readonly) NSInteger second; // 接通后的秒数

@property(nonatomic,assign) WKRTCStatus status;

@property(nonatomic,strong,readonly) NSArray<NSString*> *participantUIDs; // 所有参与者uid


// 获取参与者的stream视图
-(WKRTCStreamView*) streamView:(NSString*)uid;

// 参与者离开
-(void) leave:(NSString*)uid reason:(NSString * __nullable)reason;

-(void) setCallType:(WKRTCCallType)callType animation:(BOOL)animation;

-(void) end;

@end

NS_ASSUME_NONNULL_END
