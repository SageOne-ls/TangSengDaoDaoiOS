//
//  WKRTCConst.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCParticipant.h"
// 呼叫类型
typedef enum : NSUInteger {
    WKRTCCallTypeAudio = 0, // 语音呼叫
    WKRTCCallTypeVideo, // 视频呼叫
} WKRTCCallType;



// rtc模式
typedef enum : NSUInteger {
    WKRTCModeP2P = 0, // 单聊模式
    WKRTCModeConference, // 会议模式
} WKRTCMode;


typedef void(^ParticipantCallback)(WKRTCParticipant*participant);
