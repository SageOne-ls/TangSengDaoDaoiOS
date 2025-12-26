//
//  WKRTCStreamView.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCStreamView.h"
#import "WKRTCCommonUtil.h"
#import <DGActivityIndicatorView/DGActivityIndicatorView.h>
#import <WuKongBase/WuKongBase.h>

@interface WKRTCStreamView ()<RTCVideoViewDelegate>


@property(nonatomic,strong) DGActivityIndicatorView *activityIndicatorView;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) UIImageView *talkingIconImgView; // talking
@property(nonatomic,strong) UIImageView *muteIconImgView;

//@property(nonatomic,strong) AVCaptureSession *captureSession;

@end

@implementation WKRTCStreamView

-(instancetype) initWithFrame:(CGRect)frame{
    return [self initWithFrame:frame videoView:[[RTCEAGLVideoView alloc] initWithFrame:CGRectZero]];
}

-(instancetype) initWithFrame:(CGRect)frame videoView:(id)videoView {
    self = [super initWithFrame:frame];
    if(self) {
        self.clipsToBounds = YES;
//        self.videoSize = CGSizeMake(640, 480);
        self.videoView = videoView;
        if([videoView isKindOfClass:RTCEAGLVideoView.class]) {
            ((RTCEAGLVideoView*)self.videoView).delegate = self;
        }
        [self addSubview:self.videoView];
        [self addSubview:self.placeholder];
        [self addSubview:self.talkingIconImgView];
        [self addSubview:self.muteIconImgView];
        
        [self.placeholder addSubview:self.activityIndicatorView];
        
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.videoView.frame = self.bounds;
    self.placeholder.frame = self.bounds;
    self.videoView.subviews.firstObject.frame = self.videoView.bounds;
    self.activityIndicatorView.lim_centerX_parent = self.placeholder;
    self.activityIndicatorView.lim_centerY_parent = self.placeholder;
    
    self.talkingIconImgView.lim_left = 5.0f;
    self.talkingIconImgView.lim_top = self.lim_height - self.talkingIconImgView.lim_height - 5.0f;
    
    self.muteIconImgView.lim_origin = self.talkingIconImgView.lim_origin;
    
    if(!CGSizeEqualToSize(self.videoSize, CGSizeZero)) {
        CGSize size = [WKRTCCommonUtil convertVideoSize:self.videoSize ToViewSize:self.frame.size];
        
        self.videoView.frame = CGRectMake(0, 0, size.width, size.height);
        self.videoView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        self.videoView.subviews.firstObject.frame = self.videoView.bounds;
    }
    if(self.onLayoutSubviews) {
        self.onLayoutSubviews();
    }
}

- (void)setTimeout:(NSInteger)timeout {
    _timeout = timeout;
    if(self.stream) {
        return;
    }
    if(timeout>0) {
        [self.activityIndicatorView startAnimating];
        [self startTimer];
    }else{
        [self stopTimer];
    }
}

- (UIImageView *)placeholder {
    if(!_placeholder) {
        _placeholder = [[UIImageView alloc] init];
        _placeholder.clipsToBounds  = YES;
        _placeholder.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _placeholder;
}

- (UIImageView *)talkingIconImgView {
    if(!_talkingIconImgView) {
        _talkingIconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 24.0f, 24.0f)];
        _talkingIconImgView.image = LImage(@"talking_highlight");
        _talkingIconImgView.alpha = 0.0f;
    }
    return _talkingIconImgView;
}

- (UIImageView *)muteIconImgView {
    if(!_muteIconImgView) {
        _muteIconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 24.0f, 24.0f)];
        _muteIconImgView.image = LImage(@"mute_audio");
        _muteIconImgView.hidden = YES;
    }
    return _muteIconImgView;
}


- (void)startTimer {
    [self stopTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerClick) userInfo:nil repeats:true];
}

-(void) stopTimer {
    if(self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)setTalking:(BOOL)talking {
    _talking = talking;
    if(talking) {
        _talkingIconImgView.alpha = 1.0f;
    }else {
        _talkingIconImgView.alpha = 0.0f;
    }
}

-(void) timerClick {
    self.timeout --;
    
    if(self.timeout<=0) {
        [self stopTimer];
        if(self.onTimeout) {
            self.onTimeout();
        }
    }
}

//-(instancetype) initWithCaptureSession:(AVCaptureSession*)captureSession {
//    self = [super init];
//    if(self) {
//        self.captureSession = captureSession;
//    }
//    return self;
//}

-(void) renderStream:(WKRTCStream*)stream {
    [self stopTimer];
    self.stream = stream;
    
   
    [stream attach:self.videoView];
    
    [self.activityIndicatorView stopAnimating];
}

- (void)setMute:(BOOL)mute {
    self.stream.mute = mute;
    self.muteIconImgView.hidden = !mute;
    self.talkingIconImgView.hidden = mute;
}

- (BOOL)mute {
    return self.stream.mute;
}

-(void) unreaderStream {
    if(self.stream) {
        [self.stream unattach];
    }
}

-(void) switchCamera {
    if(self.stream) {
        [self.stream switchCamera];
    }
}

- (void)setOpenVideo:(BOOL)openVideo {
    if(self.stream) {
        self.stream.openVideo = openVideo;
    }
    self.placeholder.hidden = openVideo;
    self.talkingIconImgView.hidden = openVideo;
}

- (BOOL)openVideo {
    if(self.stream) {
        return self.stream.openVideo;
    }
    return  false;
}

- (DGActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[DGActivityIndicatorView alloc] initWithType:DGActivityIndicatorAnimationTypeThreeDots tintColor:[UIColor whiteColor]];
    }
    return _activityIndicatorView;
}

#pragma mark -- RTCVideoViewDelegate

- (void)videoView:(id<RTCVideoRenderer>)videoView didChangeVideoSize:(CGSize)size {
    if(self.fixedSize) {
        return;
    }
    self.videoSize = size;
    [self layoutSubviews];
}

- (void)dealloc {
    NSLog(@"WKRTCStreamView dealloc");
    [self stopTimer];
}

@end
