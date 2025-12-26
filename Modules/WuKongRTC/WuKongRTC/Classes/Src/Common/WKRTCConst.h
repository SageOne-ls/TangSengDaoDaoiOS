//
//  WKRTCConst.h
//  WuKongRTC
//
//  Created by tt on 2021/5/10.
//


//// 呼叫类型
//typedef enum : NSUInteger {
//    WKCallTypeAudio = 0, // 语音呼叫
//    WKCallTypeVideo, // 视频呼叫
//} WKCallType;

// 视图类型
typedef enum : NSUInteger {
    WKRTCViewTypeCall = 0, // 呼叫
    WKRTCViewTypeResponse, //响应呼叫
} WKRTCViewType;

typedef enum : NSUInteger {
    WKRTCReceiveStatusHangup, // 挂断
    WKRTCReceiveStatusAnswer // 已接听
} WKRTCReceiveStatus;

typedef enum : NSUInteger {
    WKRTCMuteTypeUnknown,
    WKRTCMuteTypeAudio,
    WKRTCMuteTypeVideo
} WKRTCMuteType;

typedef enum : NSUInteger {
    WKRTCStatusUnknown, // 未知
    WKRTCStatusConnecting, // 连接中
    WKRTCStatusCalling, // 呼叫中
    WKRTCStatusAccepting, // 接听中
    WKRTCStatusStartTalking, // 开始聊天
    WKRTCStatusEndTalking, // 结束聊天
    WKRTCStatusP2PAccepted, //单聊 已接受聊天
} WKRTCStatus;
