//
//  WKP2PChatView.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKP2PChatView.h"

#import "WKApp.h"
#import <WuKongBase/WuKongBase.h>
#import "WKRTCManager.h"
#import <WebRTC/WebRTC.h>
#import "RTCCaptureController.h"
#import "WKRTCCommonUtil.h"
#import "WKRTCActionButton.h"
#import "WKP2PChatUserView.h"
#import "WKRTCP2PChatBottomView.h"
#define WKMinWindowWidth 120.0f
#define WKMinWindowHeight 160.0f

#define WKMinWindowRightSpace 10.0f // 小窗口离右边的距离
#define WKMinWindowTopSpace (80.0f) // 小窗口离顶部的距离
@interface WKP2PChatView ()

@property(nonatomic,assign) WKRTCStatus statusInner;

@property(nonatomic,assign) WKRTCViewType viewType;
@property(nonatomic,strong) NSArray<WKRTCParticipant*> *participants;

@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) NSInteger talkSecond; // 聊天时间

@property(nonatomic,assign) BOOL isZoomOut; // 是否缩小



@property(nonatomic,strong) UIImageView *talkingIconImgView; // 缩小后的talking的icon
@property(nonatomic,assign) CGPoint voiceMinPoint; // 语音小窗口的位置

@property(nonatomic,assign) BOOL showOtherUI;

@property(nonatomic,assign) WKRTCCallType callType;

// ---------- 界面 ----------

//@property(nonatomic,strong) UIView *view;
//@property(nonatomic,strong) WKRTCP2PView *p2pView;

@property(nonatomic,strong) WKRTCStreamView *localVideoView; // 本地视频，自己

@property(nonatomic,strong) WKRTCStreamView *remoteVideoView; // 远程视频，对方

@property(nonatomic,assign) BOOL remoteViewChangeToBig; // 远程视频改变为大

@property(nonatomic,strong) UILabel *timeLbl;

@property(nonatomic,strong) UIButton *minBtn; // 缩小

@property(nonatomic,strong) WKP2PChatUserView *userView;


// ---------- 缩小后的UI ----------

@property(nonatomic,strong) UIImageView *talkImgView;
@property (nonatomic, strong)UIPanGestureRecognizer *minPanTap; // 小窗口滑动手势
@property(nonatomic,strong) UITapGestureRecognizer *zoomInTap; // 放大事件
@property (nonatomic, strong)UITapGestureRecognizer *hideOtherUITap; // 点击隐藏其他UI

#define minWidth 90.0f
#define minHeight 90.0f

@end

@implementation WKP2PChatView

+(WKP2PChatView*) participants:(NSArray<WKRTCParticipant*>*)participants viewType:(WKRTCViewType)viewType callType:(WKRTCCallType)callType{
    WKP2PChatView *vw = [[WKP2PChatView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [vw setBackgroundColor:[UIColor blackColor]];
    vw.participants = participants;
    vw.viewType = viewType;
    vw.callType = callType;
    [vw setup];
    return vw;
}

-(NSString*) callUID {
    if(self.participants && self.participants.count>0) {
        for (WKRTCParticipant *participant in self.participants) {
            if(![participant.uid isEqualToString:WKRTCManager.shared.options.uid]) {
                return participant.uid;
            }
        }
    }
    return @"";
}

-(WKRTCStreamView*) streamView:(NSString*)uid {
    if([uid isEqualToString:WKRTCManager.shared.options.uid]) {
        return self.localVideoView;
    }
    return self.remoteVideoView;
}

-(void) setup {
    CGFloat safeTop = 0.0f;
    CGFloat safeBottom = 0.0f;
    safeTop =  self.window.safeAreaInsets.top;
    safeBottom =  self.window.safeAreaInsets.bottom;
    self.lim_top = -self.lim_height;
    self.showOtherUI = true;
    
    [self addGestureRecognizer:self.hideOtherUITap];

    [self addViews];
    
    __weak typeof(self) weakSelf = self;
    
    NSString *status = @"邀请你语音通话";
    if(self.callType == WKCallTypeVideo) {
        status = @"邀请你视频通话";
    }
    if(self.viewType == WKRTCViewTypeCall) {
        status = @"等待接听...";
    }
    self.userView.statusLbl.text = status;
    [ self.userView.statusLbl sizeToFit];
    
    self.timeLbl.text = status;
    [self.timeLbl sizeToFit];
    
    [WKRTCManager shared].options.getParticipant([self callUID], ^(WKRTCParticipant * _Nonnull participant) {
        if(!participant) {
            return;
        }
       
        [ weakSelf.userView.userAvatarImgView sd_setImageWithURL:participant.avatar placeholderImage:WKApp.shared.config.defaultAvatar];
        weakSelf.userView.nameLbl.text = participant.name;
        [weakSelf.userView.nameLbl sizeToFit];
    });
    
    [self performSelector:@selector(autoHangup) withObject:nil afterDelay:WKRTCManager.shared.options.p2pCallTimeout];
    
   
}

-(void) autoHangup {
    if(self.status != WKRTCStatusStartTalking && self.status != WKRTCStatusP2PAccepted && self.status != WKRTCStatusEndTalking) {
        if(self.onHangup) {
            self.onHangup();
        }
    }
}

// 自动隐藏除视频外的其他UI
-(void) autoHideOtherUI {
    if(self.callType == WKRTCCallTypeVideo && [self talking]) {
        [self showOtherUI:NO];
    }
}

-(void) showOtherUI:(BOOL)show {
    _showOtherUI = show;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHideOtherUI) object:nil];
    [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
        [self layoutSubviews];
    } completion:^(BOOL finished) {
        if(show) {
            [self performSelector:@selector(autoHideOtherUI) withObject:nil afterDelay:WKRTCManager.shared.options.videoOtherUIHideInterval];
        }
    }];
    
   
}


-(void) addViews {
//    [self addSubview:self.p2pView];
    
    [self addSubview:self.localVideoView];
    [self addSubview:self.remoteVideoView];
    
    [self addSubview:self.userView];
    [self addSubview:self.minBtn];
    [self addSubview:self.talkingIconImgView];
    [self addSubview:self.timeLbl];
    
    [self addSubview:self.bottomView];
   
}

- (void)setStatus:(WKRTCStatus)status {
    _statusInner = status;
    self.bottomView.status = status;
    self.userView.status = status;
    if(status == WKRTCStatusConnecting) {
        self.timeLbl.text = @"连接中...";
        [self.timeLbl sizeToFit];
    }
    [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
        [self layoutSubviews];
        [self.bottomView layoutSubviews];
    }];
   
    if([self talking]) {
        [self startTimer];
        if(self.callType == WKRTCCallTypeVideo) {
            [self performSelector:@selector(autoHideOtherUI) withObject:nil afterDelay:WKRTCManager.shared.options.videoOtherUIHideInterval];
        }
    }else if(status == WKRTCStatusEndTalking) {
        if(self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
    }
}


-(void) setCallType:(WKRTCCallType)callType animation:(BOOL)animation {
    self.callType = callType;
    self.bottomView.callType = callType;
    self.userView.callType = callType;
    if(self.callType == WKRTCCallTypeAudio) {
        self.showOtherUI = YES;
    }
    if(animation) {
        [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
            if(self.isZoomOut) {
                [self zoomOut:NO];
            }else{
                [self zoomIn:NO];
            }
        }];
    }else{
        if(self.isZoomOut) {
            [self zoomOut:NO];
        }else{
            [self zoomIn:NO];
        }
    }
   
}


- (WKRTCStatus)status {
    return self.statusInner;
}

- (NSInteger)second {
    return self.talkSecond;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    

    [self layout];
}

-(void) showUI {

    self.remoteVideoView.hidden = YES;

    self.timeLbl.hidden = YES;
    self.remoteVideoView.hidden = YES;
    self.localVideoView.hidden = YES;
//    self.bottomView.hidden = YES;

    self.talkingIconImgView.hidden = YES;
    
    
    
    self.minBtn.hidden = NO;
    self.bottomView.hidden = NO;
    if(self.callType == WKRTCCallTypeVideo) {
        self.localVideoView.hidden = NO;
    }else{
        if(self.isZoomOut) {
            self.talkingIconImgView.hidden = NO;
        }
    }
    
    
    if(self.status == WKRTCStatusStartTalking || self.status == WKRTCStatusP2PAccepted) {
        
        if(self.callType == WKRTCCallTypeVideo) {
            self.remoteVideoView.hidden = NO;
        }
    }
   
}

-(void) layout {
    
    if(self.status == WKRTCStatusEndTalking) {
        return;
    }
    CGFloat safeTop = 0.0f;
    CGFloat safeBottom = 0.0f;
    safeTop =  self.window.safeAreaInsets.top;
    safeBottom =  self.window.safeAreaInsets.bottom;
    
  
    if(self.showOtherUI) {
        self.minBtn.lim_top = [self safeTop] + 10.0f;
    }else{
        self.minBtn.lim_top = -self.minBtn.lim_height;
    }

    if(self.callType == WKRTCCallTypeAudio) {
        [self layoutAudio];
    }else{
      
        [self layoutVideo];
    }
}

-(void) layoutAudio {
    self.remoteVideoView.hidden = YES;
    self.localVideoView.hidden = YES;
    
    self.talkingIconImgView.hidden = !self.isZoomOut;
    self.timeLbl.hidden = !self.isZoomOut;
    
    self.userView.hidden = NO;
    self.bottomView.hidden = NO;
    
    self.userView.lim_top = self.minBtn.lim_bottom + 80.0f;
    
    self.userView.lim_width = self.lim_width;
    self.userView.lim_left = 0.0f;
   
    self.bottomView.lim_width = self.lim_width;
    self.bottomView.lim_top = self.lim_height -  self.bottomView.lim_height;
    
    if(self.viewType == WKRTCViewTypeResponse) {
        self.minBtn.hidden = YES;
    }else {
        self.minBtn.hidden = NO;
    }
    if(self.status == WKRTCStatusStartTalking || self.status == WKRTCStatusP2PAccepted) {
        self.minBtn.hidden = NO;
    }
    
    
    for (UIView *subview in  self.subviews) {
        
        subview.alpha = self.isZoomOut?0.0f:1.0f;
    }
    
    
    if(self.isZoomOut) {
        self.talkingIconImgView.alpha = 1.0f;
        self.timeLbl.alpha = 1.0f;
        
        self.talkingIconImgView.lim_centerX_parent = self;
        self.talkingIconImgView.lim_top = 8.0f;
        self.timeLbl.lim_top = self.talkingIconImgView.lim_bottom + 8.0f;
        self.timeLbl.lim_centerX_parent = self;
    }else{
        self.talkingIconImgView.alpha = 0.0f;
        self.timeLbl.alpha = 0.0f;
    }
    
}


-(void) layoutVideo {
    self.remoteVideoView.hidden = YES;
    self.localVideoView.hidden = NO;
    self.talkingIconImgView.hidden = YES;
    self.bottomView.hidden = NO;
    
    self.bottomView.lim_width = self.lim_width;
    if(self.showOtherUI) {
        self.bottomView.lim_top = self.lim_height -  self.bottomView.lim_height;
    }else{
        self.bottomView.lim_top = self.lim_height;
    }
    
    self.userView.lim_top = 20.0f +  self.minBtn.lim_bottom;
    self.userView.lim_left = 20.0f;
    
    
    self.timeLbl.lim_top = self.minBtn.lim_top + 5.0f;
    self.timeLbl.lim_centerX_parent = self;
    
    for (UIView *subview in  self.subviews) {
        
        subview.alpha = self.isZoomOut?0.0f:1.0f;
    }
    
    if([self talking]) {
        self.timeLbl.hidden = NO;
        self.timeLbl.alpha = self.isZoomOut?0.0f:1.0f;
        self.bottomView.alpha = self.isZoomOut?0.0f:1.0f;
        
        self.userView.hidden = YES;
        self.remoteVideoView.hidden = NO;
        self.remoteVideoView.alpha = 1.0f;
        
        CGFloat cornerRadius = 8.0f;
        if(self.remoteViewChangeToBig) {
            self.localVideoView.layer.masksToBounds = YES;
            self.localVideoView.layer.cornerRadius = cornerRadius;
            
            self.remoteVideoView.layer.masksToBounds = YES;
            self.remoteVideoView.layer.cornerRadius = 0.0f;
        }else{
            
            self.localVideoView.layer.masksToBounds = YES;
            self.localVideoView.layer.cornerRadius = 0.0f;
            
            self.remoteVideoView.layer.masksToBounds = YES;
            self.remoteVideoView.layer.cornerRadius = cornerRadius;
        }
        if(self.isZoomOut) {
            self.layer.masksToBounds = YES;
            self.layer.cornerRadius = cornerRadius;
        }else{
            self.layer.masksToBounds = YES;
            self.layer.cornerRadius = 0;
        }
        
        
        if(self.isZoomOut) {
            self.remoteVideoView.lim_size = self.bounds.size;
            self.localVideoView.lim_size = self.bounds.size;
        }else{
            if(self.remoteViewChangeToBig) { // 远程视频变大
                self.remoteVideoView.lim_size = self.bounds.size;
                CGSize size = [WKRTCCommonUtil convertVideoSize:self.localVideoView.videoSize ToViewSize:CGSizeMake(WKMinWindowWidth, WKMinWindowHeight)];
                self.localVideoView.lim_size = size;
            }else {
                CGSize size = [WKRTCCommonUtil convertVideoSize:self.remoteVideoView.videoSize ToViewSize:CGSizeMake(WKMinWindowWidth, WKMinWindowHeight)];
                self.localVideoView.lim_size = self.bounds.size;
                self.remoteVideoView.lim_size = size;
            }
        }
    }else{
        self.userView.hidden = NO;
        self.timeLbl.hidden = YES;
        
        self.localVideoView.alpha = 1.0f;
        if(self.isZoomOut) {
            [self localVideoViewToSmall];
        }else{
            [self localVideoViewToBig];
        }
    }
    
   
}

-(BOOL) talking {
    return self.status == WKRTCStatusStartTalking || self.status == WKRTCStatusP2PAccepted;
}

-(void) localVideoViewToSmall {
    CGFloat safeTop = 0.0f;
    safeTop =  self.window.safeAreaInsets.top;
    CGSize size = [WKRTCCommonUtil convertVideoSize:self.localVideoView.videoSize ToViewSize:CGSizeMake(WKMinWindowWidth, WKMinWindowHeight)];
    self.localVideoView.frame = CGRectMake(0.0f,0.0f, size.width, size.height);
}

-(void) remoteVideoViewToSmall {
    CGFloat safeTop = 0.0f;
    safeTop =  self.window.safeAreaInsets.top;
    CGSize size = [WKRTCCommonUtil convertVideoSize:self.remoteVideoView.videoSize ToViewSize:CGSizeMake(WKMinWindowWidth, WKMinWindowHeight)];
    self.remoteVideoView.lim_size = CGSizeMake(size.width, size.height);
}

-(void) localVideoViewToBig {
    self.localVideoView.frame =  [UIScreen mainScreen].bounds;
}



// 切换本地和远程视频显示view
-(void) switchVideoView {
   
    self.remoteViewChangeToBig = !self.remoteViewChangeToBig;
    [self.localVideoView removeGestureRecognizer:self.minPanTap];
    [self.remoteVideoView removeGestureRecognizer:self.minPanTap];
    if(self.remoteViewChangeToBig) {
        self.remoteVideoView.userInteractionEnabled = NO;
        self.localVideoView.userInteractionEnabled = YES;
        self.localVideoView.alpha = 0.0f;
        [self bringSubviewToFront:self.localVideoView];
        [self.localVideoView addGestureRecognizer:self.minPanTap];
    }else{
        self.remoteVideoView.userInteractionEnabled = YES;
        self.localVideoView.userInteractionEnabled = NO;
        self.remoteVideoView.alpha = 0.0f;
        [self bringSubviewToFront:self.remoteVideoView];
        [self.remoteVideoView addGestureRecognizer:self.minPanTap];
    }
    [self bringSubviewToFront:self.minBtn];
    [self bringSubviewToFront:self.bottomView];
    
    CGPoint minPoint;
    if(self.remoteViewChangeToBig) {
        minPoint = self.remoteVideoView.lim_origin;
    }else{
        minPoint = self.localVideoView.lim_origin;
    }
    [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
        [self layoutSubviews];
        
        self.remoteVideoView.alpha = 1.0f;
        self.localVideoView.alpha = 1.0f;
        [self.remoteVideoView layoutSubviews];
        [self.localVideoView layoutSubviews];
        
        if(self.remoteViewChangeToBig) {
            self.localVideoView.lim_origin = minPoint;
            self.remoteVideoView.lim_origin = CGPointMake(0.0f, 0.0f);
        }else{
            self.remoteVideoView.lim_origin = minPoint;
            self.localVideoView.lim_origin = CGPointMake(0.0f, 0.0f);
        }
      
    }];
}


-(CGFloat) safeBottom {
    return  self.window.safeAreaInsets.bottom;
}

-(CGFloat) safeTop {
    return  self.window.safeAreaInsets.top;
}


#pragma mark -- init

- (WKP2PChatUserView *)userView {
    if(!_userView) {
        _userView = [[WKP2PChatUserView alloc] initWithViewType:self.viewType callType:self.callType];
//        _userView.backgroundColor = [UIColor redColor];
    }
    return _userView;
}

- (WKRTCP2PChatBottomView *)bottomView {
    if(!_bottomView) {
        _bottomView = [[WKRTCP2PChatBottomView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.lim_width, 240.0f+ [self safeBottom] ) status:self.status viewType:self.viewType callType:self.callType];
        _bottomView.lim_top = self.lim_height -  _bottomView.lim_height;
//        [_bottomView setBackgroundColor:[UIColor blueColor]];
        __weak typeof(self) weakSelf = self;
        _bottomView.onHangup = ^{
            if(weakSelf.onHangup) {
                weakSelf.onHangup();
            }
        };
        _bottomView.onAnswer = ^{
            if(weakSelf.onAccepted) {
                weakSelf.onAccepted();
            }
        };
        _bottomView.onMute = ^(BOOL on) {
            if(weakSelf.onMute) {
                weakSelf.onMute(on);
            }
        };
        _bottomView.onHandsFree = ^(BOOL on) {
            if(weakSelf.onHandsFree) {
                weakSelf.onHandsFree(on);
            }
        };
        _bottomView.onCameraToggle = ^(BOOL on) {
            if(weakSelf.onSwitchCamera) {
                weakSelf.onSwitchCamera();
            }
        };
        _bottomView.onCameraSwitch = ^(BOOL on) {
            if(weakSelf.onSwitch) {
                weakSelf.onSwitch();
            }
        };
    }
    return _bottomView;
}

- (UIImageView *)talkingIconImgView {
    if(!_talkingIconImgView) {
        _talkingIconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
        _talkingIconImgView.alpha = 0.0f;
        _talkingIconImgView.image = LImage(@"talking_icon");
    }
    return _talkingIconImgView;
}



- (WKRTCStreamView *)localVideoView {
    if(!_localVideoView) {
        CGFloat safeTop = 0.0f;
        safeTop = self.window.safeAreaInsets.top;
        _localVideoView = [[WKRTCStreamView alloc] initWithFrame:self.bounds videoView:[[RTCCameraPreviewView alloc] init]];
        _localVideoView.videoSize = CGSizeMake(480.0f, 640.0f);
       
        _localVideoView.userInteractionEnabled = NO;
        [_localVideoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchVideoView)]];
        
//        __weak typeof(_localVideoView) localVideoViewWeak = _localVideoView;
//        __weak typeof(self) weakSelf = self;
//        [_localVideoView setOnLayoutSubviews:^{
//            if(weakSelf.remoteViewChangeToBig) {
//                localVideoViewWeak.lim_left = weakSelf.lim_width - localVideoViewWeak.lim_width - WKMinWindowRightSpace;
//                localVideoViewWeak.lim_top = safeTop + WKMinWindowTopSpace;
//            }
//
//        }];
        
    }
    return _localVideoView;
}

- (WKRTCStreamView *)remoteVideoView {
    if(!_remoteVideoView) {
        CGFloat safeTop = 0.0f;
        safeTop = self.window.safeAreaInsets.top;
        _remoteVideoView = [[WKRTCStreamView alloc] initWithFrame: CGRectMake(0.0f, 0.0f, WKMinWindowWidth, WKMinWindowHeight)];
        _remoteVideoView.videoSize = CGSizeMake(480.0f, 640.0f);
        _remoteVideoView.userInteractionEnabled = YES;
        [_remoteVideoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchVideoView)]];
        [_remoteVideoView addGestureRecognizer:self.minPanTap];
        
        _remoteVideoView.lim_left = self.lim_width - _remoteVideoView.lim_width - WKMinWindowRightSpace;
        _remoteVideoView.lim_top = safeTop + WKMinWindowTopSpace;
    }
    return _remoteVideoView;
}


- (UIButton *)minBtn {
    if(!_minBtn) {
        _minBtn = [[UIButton alloc] initWithFrame:CGRectMake(20.0f, 0.0f, 32.0f, 32.0f)];
        [_minBtn setImage:[self imageName:@"call_min"] forState:UIControlStateNormal];
        [_minBtn addTarget:self action:@selector(minPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _minBtn;
}
    
// 缩小
-(void) minPressed {
    [self zoomOut];
}

// 缩小
-(void) zoomOut {
    [self zoomOut:YES];
}

-(void) zoomOut:(BOOL)animation{
    self.isZoomOut = true;

    if(self.callType == WKRTCCallTypeVideo) {
        self.remoteVideoView.userInteractionEnabled = NO;
        self.localVideoView.userInteractionEnabled = NO;
        if([self talking]) {
            [self showOtherUI:NO];
        }
    }else {
        self.timeLbl.font = [WKApp.shared.config appFontOfSizeMedium:14.0f];
        self.timeLbl.textColor = WKApp.shared.config.themeColor;
        [self.timeLbl sizeToFit];
    }
    
    [self removeGestureRecognizer:self.hideOtherUITap];
    [self addGestureRecognizer:self.zoomInTap];
    [self addGestureRecognizer:self.minPanTap];
    
    if(animation) {
        [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
            
            [self zoomLayoutFrame];
            [self layoutSubviews];
          
            if(self.callType == WKRTCCallTypeVideo) {
                [self.remoteVideoView layoutSubviews];
                [self.localVideoView layoutSubviews];
            }
            
            [self.userView layoutSubviews];
            [self.bottomView layoutSubviews];
           
            
        }];
    }else{
        [self zoomLayoutFrame];
        [self layoutSubviews];
      
        if(self.callType == WKRTCCallTypeVideo) {
            [self.remoteVideoView layoutSubviews];
            [self.localVideoView layoutSubviews];
        }
        
        [self.userView layoutSubviews];
        [self.bottomView layoutSubviews];
    }
   
}

-(void) zoomIn:(BOOL) animation {
    self.isZoomOut = NO;
    self.remoteVideoView.userInteractionEnabled = NO;
    self.localVideoView.userInteractionEnabled = NO;
    [self removeGestureRecognizer:self.zoomInTap];
    [self removeGestureRecognizer:self.minPanTap];
    if([self talking] && self.callType == WKRTCCallTypeVideo) {
        [self showOtherUI:YES];
        [self addGestureRecognizer:self.hideOtherUITap];
    }
    
    
    self.timeLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
    self.timeLbl.textColor = [UIColor whiteColor];
    [self.timeLbl sizeToFit];
    
    void(^animationLayoutUI)(void) = ^{
        [self zoomLayoutFrame];
        [self layoutSubviews];
        
        if(self.callType == WKRTCCallTypeVideo) {
            [self.remoteVideoView layoutSubviews];
            [self.localVideoView layoutSubviews];
        }
        [self.userView layoutSubviews];
        [self.bottomView layoutSubviews];
    };
    
    void(^completionLayoutUI)(void) = ^{
        if(self.callType == WKRTCCallTypeVideo) {
            if(self.remoteViewChangeToBig) {
                [self.localVideoView addGestureRecognizer:self.minPanTap];
                self.localVideoView.userInteractionEnabled = YES;
            }else{
                [self.remoteVideoView addGestureRecognizer:self.minPanTap];
                self.remoteVideoView.userInteractionEnabled = YES;
            }
        }
    };
    
    // WKApp.shared.config.defaultAnimationDuration
    if(animation) {
        [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
           
            animationLayoutUI();
           
        } completion:^(BOOL finished) {
            completionLayoutUI();
        }];
    }else{
        animationLayoutUI();
        
        completionLayoutUI();
    }
    
}

// 放大
-(void) zoomIn {
    [self zoomIn:YES];
}
    
-(void) zoomLayoutFrame {
    
    if(!self.isZoomOut) {
        if(self.callType == WKRTCCallTypeVideo) {
            CGPoint smallPoint = CGPointZero;
            if(!CGPointEqualToPoint(self.lim_origin, CGPointZero)) {
                smallPoint = self.lim_origin;
            }else{
                CGFloat videoWidth = 0.0f;
                if(self.remoteViewChangeToBig) {
                    videoWidth = self.localVideoView.lim_width;
                }else{
                    videoWidth = self.remoteVideoView.lim_width;
                }
                smallPoint = CGPointMake(self.lim_width -videoWidth - WKMinWindowRightSpace, [self safeTop] + WKMinWindowTopSpace);
            }
            
            if(self.remoteViewChangeToBig) {
                self.localVideoView.lim_origin = smallPoint;
            }else {
                self.remoteVideoView.lim_origin = smallPoint;
            }
            
        }else {
            self.voiceMinPoint = self.lim_origin;
            self.layer.cornerRadius = 0.0f;
            self.layer.shadowOffset = CGSizeMake(0, 0);
            self.layer.shadowOpacity = 0;
            self.layer.shadowRadius = 0;
        }
        self.backgroundColor = [UIColor blackColor];
        self.frame = [UIScreen mainScreen].bounds;
       
        return;
    }
    
    CGFloat safeTop = 0.0f;
    safeTop = self.window.safeAreaInsets.top;
    
    CGSize minSize;
    CGPoint minWindowPoint;
    if(self.callType == WKRTCCallTypeVideo) {
        CGSize videoSize;
        if([self talking]) {
            videoSize = [WKRTCCommonUtil convertVideoSize:self.remoteVideoView.videoSize ToViewSize:CGSizeMake(WKMinWindowWidth, WKMinWindowHeight)];
        }else {
            videoSize = [WKRTCCommonUtil convertVideoSize:self.localVideoView.videoSize ToViewSize:CGSizeMake(WKMinWindowWidth, WKMinWindowHeight)];
        }
        
        if(self.remoteViewChangeToBig) {
            minWindowPoint = self.localVideoView.lim_origin;
        }else{
            minWindowPoint = self.remoteVideoView.lim_origin;
        }
        
        
        self.remoteVideoView.lim_origin = CGPointMake(0.0f, 0.0f);
        self.localVideoView.lim_origin =  CGPointMake(0.0f, 0.0f);
        
        minSize = videoSize;
        
        
    }else {
        minSize = CGSizeMake(80.0f, 80.0f);
        if(CGPointEqualToPoint(self.voiceMinPoint, CGPointZero)) {
            self.voiceMinPoint = CGPointMake(WKScreenWidth - minSize.width - WKMinWindowRightSpace, safeTop+WKMinWindowTopSpace);
        }
        minWindowPoint = self.voiceMinPoint;
    }
    
    if(!CGPointEqualToPoint(self.lim_origin, CGPointZero)) {
        minWindowPoint = self.lim_origin;
    }
    
    self.frame = CGRectMake(minWindowPoint.x, minWindowPoint.y, minSize.width, minSize.height);
    
    if(self.callType == WKRTCCallTypeAudio) {
        self.backgroundColor = [UIColor whiteColor];
//        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 8.0f;
        self.layer.shadowOffset = CGSizeMake(2, 2);
        self.layer.shadowOpacity = 0.1f;
        self.layer.shadowRadius = 2;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
    }
}


- (UITapGestureRecognizer *)hideOtherUITap {
    if(!_hideOtherUITap) {
        _hideOtherUITap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideOtherPressed)];
    }
    return _hideOtherUITap;
}

- (UIPanGestureRecognizer *)minPanTap {
    if(!_minPanTap) {
        _minPanTap = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(minPanPressed:)];
    }
    return _minPanTap;
}

-(void) hideOtherPressed {
    if(self.callType == WKRTCCallTypeVideo && [self talking]) {
        [self showOtherUI:!self.showOtherUI];
    }
}

-(void) minPanPressed:(UIPanGestureRecognizer *)rec {
    
    CGFloat safeTop = 0.0f;
    CGFloat safeBottom = 0.0f;
    safeBottom =  self.window.safeAreaInsets.bottom;
    safeTop =  self.window.safeAreaInsets.top;
    CGFloat KWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat KHeight = [UIScreen mainScreen].bounds.size.height;
    
    //返回在横坐标上、纵坐标上拖动了多少像素
    CGPoint point=[rec translationInView:rec.view];
    NSLog(@"%f,%f",point.x,point.y);
    
    CGFloat endX = rec.view.center.x+point.x;
        
    CGFloat endY = rec.view.center.y+point.y;
    
    CGFloat viewHalfH = rec.view.frame.size.height/2;
    CGFloat viewhalfW = rec.view.frame.size.width/2;
    
    CGFloat screenHeight = WKScreenHeight;
    CGFloat screentWidth = WKScreenWidth;
    
    if (rec.state == UIGestureRecognizerStateEnded) {
        //计算距离最近的边缘 吸附到边缘停靠

        CGFloat topRange = endY;//上距离
        CGFloat bottomRange = screenHeight - endY;//下距离
        CGFloat leftRange = endX;//左距离
        CGFloat rightRange = screentWidth - endX;//右距离
        
        //比较上下左右距离 取出最小值
        CGFloat minRangeTB = topRange > bottomRange ? bottomRange : topRange;//获取上下最小距离
        CGFloat minRangeLR = leftRange > rightRange ? rightRange : leftRange;//获取左右最小距离
        CGFloat minRange = minRangeTB > minRangeLR ? minRangeLR : minRangeTB;//获取最小距离
        
        
        //判断最小距离属于上下左右哪个方向 并设置该方向边缘的point属性
        CGPoint minPoint;
        if (minRange == topRange) {
            //上
            endX = endX - viewhalfW < 0 ? viewhalfW : endX;
            endX = endX + viewhalfW > KWidth ? KWidth - viewhalfW : endX;
            minPoint = CGPointMake(endX , 0 + viewHalfH+safeTop);
        } else if(minRange == bottomRange){
            //下
            endX = endX - viewhalfW < 0 ? viewhalfW : endX;
            
            endX = endX + viewhalfW > KWidth ? KWidth - viewhalfW : endX;
            
            minPoint = CGPointMake(endX , KHeight - viewHalfH - safeBottom);
            
        } else if(minRange == leftRange){
            //左
            endY = endY - viewHalfH - safeTop < 0 ? viewHalfH + safeTop : endY;
            endY = endY + viewHalfH + safeBottom > KHeight ? KHeight - viewHalfH - safeBottom : endY;
            minPoint = CGPointMake(0 + viewhalfW , endY);
        } else {
            
            //右
            endY = endY - viewHalfH - safeTop < 0 ? viewHalfH + safeTop : endY;
            endY = endY + viewHalfH + safeBottom > KHeight ? KHeight - viewHalfH - safeBottom : endY;
            minPoint = CGPointMake(KWidth - viewhalfW , endY);
            
        }
        //添加吸附物理行为
//        UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:rec.view attachedToAnchor:minPoint];
//        [attachmentBehavior setLength:0];
//        [attachmentBehavior setDamping:0.05];
//        [attachmentBehavior setFrequency:8];
//        [self.animator addBehavior:attachmentBehavior];
        
    
        [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
            rec.view.lim_top = minPoint.y - viewHalfH;
            rec.view.lim_left = minPoint.x - viewhalfW;

        }];
        
        
               
    }else  {
        // 移除之前的所有行为
//        [self.animator removeAllBehaviors];
        
        rec.view.center = CGPointMake(endX, endY);
    }
    
    //拖动完之后，每次都要用setTranslation:方法制0这样才不至于不受控制般滑动出视图
      [rec setTranslation:CGPointMake(0, 0) inView:self];

}

- (UITapGestureRecognizer *)zoomInTap {
    if(!_zoomInTap) {
        _zoomInTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomInTapPressed)];
    }
    return _zoomInTap;
}

// 放大
-(void) zoomInTapPressed {
    [self zoomIn];
   
    
//    [self addViews];
//    [UIView animateWithDuration:0.2f animations:^{
//        self.frame = [UIScreen mainScreen].bounds;
//        [self.p2pView zoomIn];
//        [self layout];
//        [self.p2pView layoutSubviews];
//    }];
  
}


- (void)startTimer {
    if(self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerClick) userInfo:nil repeats:true];
}
-(void) timerClick {
    self.talkSecond++;
    NSString *timeStr;
    if(self.talkSecond< 60 * 60) {
        timeStr = [NSString stringWithFormat:@"%02ld:%02ld",(long)(self.talkSecond/60),(long)(self.talkSecond%60)];
    }else {
        timeStr = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",self.talkSecond/3600,(self.talkSecond%3600)/60,(self.talkSecond%60)];
    }
    self.timeLbl.text = timeStr;
    [self.timeLbl sizeToFit];
    
    if(self.callType == WKRTCCallTypeAudio) {
        self.userView.statusLbl.text = timeStr;
        [ self.userView.statusLbl sizeToFit];
    }
    
}

- (UILabel *)timeLbl {
    if(!_timeLbl) {
        _timeLbl = [[UILabel alloc] init];
        _timeLbl.font = [WKApp.shared.config appFontOfSize:15.0f];
        _timeLbl.textColor = [UIColor whiteColor];
        _timeLbl.text = @"00:00";
        [_timeLbl sizeToFit];
    }
    return _timeLbl;
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRTC"];
}

-(void) end {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)dealloc {
    
    NSLog(@"WKP2PChatView dealloc");
}


@synthesize onAccepted;

@synthesize onHangup;

@synthesize status;

@synthesize onHandsFree;

@synthesize onMute;

@synthesize handsFree;

@synthesize second;

@synthesize onSwitch;

@synthesize onSwitchCamera;

@synthesize callType;

@synthesize participantUIDs;

@end
