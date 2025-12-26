//
//  WKRTCStreamView.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <UIKit/UIKit.h>
#import "WKRTCStream.h"
#import <AVFoundation/AVFoundation.h>
#import <WebRTC/WebRTC.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCStreamView : UIView

-(instancetype) initWithFrame:(CGRect)frame videoView:(id)videoView;

@property(nonatomic,strong) UIView *videoView;
@property(nonatomic,copy) void(^onLayoutSubviews)(void);
@property(nonatomic,strong) WKRTCStream *stream;
@property(nonatomic,strong) UIImageView *placeholder;
@property(nonatomic,assign) BOOL openVideo;

@property(nonatomic,assign) NSInteger timeout; // 超时时间，0表示永不超时
@property(nonatomic,copy) void(^onTimeout)(void); // 超时触发

@property(nonatomic,assign) BOOL mute; // 静音

@property(nonatomic,assign) BOOL talking; // 是否说话中

@property(nonatomic,assign) CGSize videoSize;

@property(nonatomic,assign) BOOL fixedSize; // 是否固定大小，设置后不会根据视频大小自动调整

@property(nonatomic,strong) id value;


//-(instancetype) initWithCaptureSession:(AVCaptureSession*)captureSession;



-(void) renderStream:(WKRTCStream*)stream;

-(void) unreaderStream;

// 切换摄像头（只支持本地流）
-(void) switchCamera;



@end

NS_ASSUME_NONNULL_END
