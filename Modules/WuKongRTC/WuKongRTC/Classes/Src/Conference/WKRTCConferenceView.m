//
//  WKRTCConferenceView.m
//  WuKongRTC
//
//  Created by tt on 2022/9/15.
//

#import "WKRTCConferenceView.h"
#import "WKRTCConferenceResponseView.h"
#import "WKRTCConferenceNavigation.h"
#import "WKRTCConferenceBottom.h"
#import "WKRTCStreamView.h"
#import "WKRTCManager.h"

#define minWindowUserSize CGSizeMake(120.0f,120.0f)

#define WKMinWindowWidth 120.0f
#define WKMinWindowHeight 160.0f

#define WKMinWindowRightSpace 10.0f // 小窗口离右边的距离
#define WKMinWindowTopSpace (80.0f) // 小窗口离顶部的距离

@interface WKRTCConferenceView ()

@property(nonatomic,assign) WKRTCStatus statusInner;
@property(nonatomic,assign) WKRTCViewType viewType;
@property(nonatomic,strong) NSMutableArray<WKRTCParticipant*> *participants;

@property(nonatomic,strong) WKRTCConferenceResponseView *responseView; // 收到通话的UI

@property(nonatomic,strong) WKRTCConferenceNavigation *navigation; // 导航栏

@property(nonatomic,strong) WKRTCConferenceBottom *bottom; // 底部

@property(nonatomic,strong) UIView *participantStreamBox;
@property(nonatomic,strong) UIScrollView *otherParticipantStreamBox;

@property(nonatomic,strong) NSString *screenUID; // 全屏用户uid
@property(nonatomic,strong) WKRTCStreamView *currentStreamView; // 当前点击的streamView

@property (nonatomic, strong)UIPanGestureRecognizer *minPanTap; // 小窗口滑动手势

@property(nonatomic,strong) UITapGestureRecognizer *zoomInTap; // 放大事件

@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,assign) NSInteger talkSecond; // 聊天时间
@property(nonatomic,strong) UILabel *timeLbl; // 时间

@property(nonatomic,assign) BOOL isZoomOut; // 是否缩小

@property(nonatomic,assign) CGPoint voiceMinPoint; // 语音小窗口的位置

@property(nonatomic,strong) UIImageView *talkingIconImgView; // 缩小后的talking的icon

@end
@implementation WKRTCConferenceView

+(WKRTCConferenceView*) participants:(NSArray<WKRTCParticipant*>*)participants viewType:(WKRTCViewType)viewType {
    WKRTCConferenceView *vw = [[WKRTCConferenceView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [vw setBackgroundColor:[UIColor colorWithRed:16.0f/255.0f green:16.0f/255.0f blue:16.0f/255.0f alpha:1.0f]];
    vw.participants = [NSMutableArray arrayWithArray:participants];
    vw.viewType = viewType;
    [vw setup];
    return vw;
}

- (nonnull WKRTCStreamView *)streamView:(nonnull NSString *)uid {
    NSArray<WKRTCStreamView*> *streamViews =  [self streamViews];
    if(streamViews && streamViews.count>0) {
        for (WKRTCStreamView *streamView in streamViews) {
            if([streamView.value isEqualToString:uid]) {
                return streamView;
            }
        }
    }
    return nil;
}


-(void) setup {
    
    [self addSubview:self.navigation];
    [self addSubview:self.participantStreamBox];
    [self.participantStreamBox addSubview:self.otherParticipantStreamBox];
    [self addSubview:self.bottom];
    [self addSubview:self.talkingIconImgView];
    [self addSubview:self.timeLbl];
    
    if(self.viewType == WKRTCViewTypeCall) {
        [self initParticipnatStreamBox];
    }else if(self.viewType == WKRTCViewTypeResponse){
        [self addSubview:self.responseView];
        self.responseView.participants = self.participants;
    }
    
    self.timeLbl.text = LLang(@"等待接听");
    [self.timeLbl sizeToFit];
    
}

-(void) initParticipnatStreamBox {
    if(self.participants && self.participants.count>0) {
        for (WKRTCParticipant *participant in self.participants) {
            [self addParticipant:participant.uid];
        }
    }
}

- (void)setStatus:(WKRTCStatus)status {
    _statusInner = status;
    if(status == WKRTCStatusStartTalking) {
        self.responseView.onHangup = nil;
        [self changeToTalkViewIfNeed];
        [self startTimer];
       
    }else if(status == WKRTCStatusConnecting) {
        self.responseView.onHangup = nil;
        [self changeToTalkViewIfNeed];
        self.navigation.timeLbl.text = LLang(@"连接中...");
        [self.navigation.timeLbl sizeToFit];
        
        self.timeLbl.text = LLang(@"连接中...");
        [self.timeLbl sizeToFit];
    }else if(status == WKRTCStatusEndTalking) {
        if(self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
    }else {
        self.timeLbl.text = LLang(@"等待接听");
        [self.timeLbl sizeToFit];
    }
    [self layoutSubviews];
}

// 改变成talking的UI
-(void) changeToTalkViewIfNeed {
    if(!self.responseView.superview) {
        return;
    }
    if(self.viewType == WKRTCViewTypeResponse) {
       
        [self.responseView removeFromSuperview];
        
        [self.otherParticipantStreamBox.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self initParticipnatStreamBox];
    }
}

- (WKRTCStatus)status {
    return _statusInner;
}

-(void) addParticipant:(NSString*)uid {
    WKRTCStreamView *streamView = [[WKRTCStreamView alloc] initWithFrame:CGRectZero];
    streamView.value = uid;
    streamView.timeout =  WKRTCManager.shared.options.joinRoomTimeout;
    __weak typeof(self) weakSelf = self;
    streamView.onTimeout = ^{
        [weakSelf timeoutLeave:uid];
    };
    UITapGestureRecognizer *streamViewTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(streamViewTap:)];
    streamView.userInteractionEnabled = YES;
    [streamView addGestureRecognizer:streamViewTap];
    
    __weak typeof(streamView) streamViewWeak = streamView;
    WKRTCManager.shared.getParticipant(uid, ^(WKRTCParticipant *participant) {
        [streamViewWeak.placeholder lim_setImageWithURL:participant.avatar placeholderImage:WKRTCManager.shared.options.defaultAvatar];
    });
    
    [self.otherParticipantStreamBox addSubview:streamView];
}

-(void) streamViewTap:(UITapGestureRecognizer*)gesture {
    WKRTCStreamView *streamView = (WKRTCStreamView*)gesture.view;
    self.currentStreamView = streamView;
    
    WKRTCStreamView *oldScreenView = [self screenStreamView];
    if(oldScreenView) {
//        CGRect oldScreenFrame =   [self.participantStreamBox convertRect:oldScreenView.frame toView:self.otherParticipantStreamBox];
//        [oldScreenView removeFromSuperview];
//        [self insertOtherParticipantStreamBox:oldScreenView];
//        oldScreenView.frame = oldScreenFrame;
        
    }
    
    if(self.screenUID  && [self.screenUID isEqualToString:streamView.value]) {
        self.screenUID = nil;
    }else{
        self.screenUID = streamView.value;
        CGPoint streamPoint  =   [self.otherParticipantStreamBox convertPoint:streamView.frame.origin toView:self.participantStreamBox];
//
        [streamView removeFromSuperview];
        [self.participantStreamBox addSubview:streamView];
//
        streamView.lim_origin = streamPoint;
    }
    
   
    [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
        
       
        if(self.screenUID) {
            self.bottom.changeToSmall = true;
        }else{
            self.bottom.changeToSmall = false;
        }
        [self.bottom layoutSubviews];
        [self layoutSubviews];
        [self.participantStreamBox layoutSubviews];
        [self.otherParticipantStreamBox layoutSubviews];

    } completion:^(BOOL finished) {
        if(oldScreenView) {
            [oldScreenView removeFromSuperview];
            [self insertOtherParticipantStreamBox:oldScreenView];
        }
        
    }];
    
}

-(void) insertOtherParticipantStreamBox:(WKRTCStreamView*)streamView {
    NSString *insertUID = streamView.value;
    NSString *preUID;
    for (WKRTCParticipant *pant in self.participants) {
        if([pant.uid isEqualToString:insertUID]) {
            break;
        }
        preUID = pant.uid;
    }
    if(!preUID) {
        [self.otherParticipantStreamBox insertSubview:streamView atIndex:0];
    }else {
        NSInteger i =0;
        for (UIView *view  in  self.otherParticipantStreamBox.subviews) {
            if([view isKindOfClass:WKRTCStreamView.class]){
                WKRTCStreamView *sview = (WKRTCStreamView*)view;
                if([sview.value isEqualToString:preUID]) {
                    break;
                }
            }
            i++;
        }
        if(i+1<self.otherParticipantStreamBox.subviews.count) {
            [self.otherParticipantStreamBox insertSubview:streamView atIndex:i+1];
        }else{
            [self.otherParticipantStreamBox addSubview:streamView];
        }
    }
}

-(void) timeoutLeave:(NSString*)uid {
    [self leave:uid reason:LLang(@"超时离开")];
}

-(void) leave:(NSString*)uid reason:(NSString * __nullable)reason{
    WKRTCStreamView *streamView = [self streamView:uid];
    if(streamView) {
        [streamView showMsg:reason];
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf leave:uid];
    });
    
}

-(void) leave:(NSString*)uid {
    NSArray<WKRTCStreamView*> *subviews = [self streamViews];
    if(subviews && subviews.count>0) {
        for (WKRTCStreamView *streamView  in subviews) {
            if([uid isEqualToString:streamView.value]) {
                [streamView removeFromSuperview];
            }
        }
    }
    if(self.participants && self.participants.count>0) {
        for (WKRTCParticipant *participant in self.participants) {
            if([participant.uid isEqualToString:uid]) {
                [self.participants removeObject:participant];
                break;
            }
        }
    }
    [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
        [self layoutSubviews];
    } completion:^(BOOL finished) {
        NSArray<WKRTCStreamView*> *subviews = [self streamViews];
        if(subviews.count <= 1) {
            if(self.onHangup) {
                self.onHangup();
            }
        }
    }];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if(self.isZoomOut) { // 缩小
        self.navigation.alpha = 0.0f;
        self.participantStreamBox.alpha = 0.0f;
        self.otherParticipantStreamBox.alpha = 0.0f;
        self.bottom.alpha = 0.0f;
        self.talkingIconImgView.alpha = 1.0f;
        
        self.timeLbl.alpha = 1.0f;
        self.talkingIconImgView.lim_centerX_parent = self;
        self.talkingIconImgView.lim_top = 10.0f;
        self.timeLbl.lim_centerX_parent = self;
        self.timeLbl.lim_top = self.talkingIconImgView.lim_bottom + 5.0f;
        return;
    }
    self.timeLbl.alpha = 0.0f;
    self.talkingIconImgView.alpha = 0.0f;
    self.navigation.alpha = 1.0f;
    self.participantStreamBox.alpha = 1.0f;
    self.otherParticipantStreamBox.alpha = 1.0f;
    self.bottom.alpha = 1.0f;
    
    
    [self showByViewType];
    
    
    [self layoutParitcipants];
    
    self.bottom.lim_top = self.lim_height - self.bottom.lim_height;
    
}

-(BOOL) hasScreenUser {
    return self.screenUID;
}

-(void) layoutParitcipants {
    

    NSArray<WKRTCStreamView*> *streamViews = [self streamViews];
    if([self hasScreenUser]) {
        [self layoutForHasScreen:streamViews];
    }else{
        [self layoutForNoHasScreen:streamViews];
    }
    
    
    self.participantStreamBox.frame = CGRectMake(0.0f, self.navigation.lim_bottom, WKScreenWidth, WKScreenHeight - self.navigation.lim_bottom - self.bottom.lim_height);
    
    if([self hasScreenUser]) {
        self.otherParticipantStreamBox.lim_size = CGSizeMake(self.lim_width, minWindowUserSize.height);
        self.otherParticipantStreamBox.lim_top = self.participantStreamBox.lim_height - self.otherParticipantStreamBox.lim_height;
        
    }else{
        self.otherParticipantStreamBox.frame  = self.participantStreamBox.bounds;
    }
    
    
    WKRTCStreamView *oldScreenView;
    WKRTCStreamView *newScreenView;
    if([self hasScreenUser]) {
        if(self.currentStreamView) {
            newScreenView = self.currentStreamView;
        }
        WKRTCStreamView *screenView = [self screenStreamView];
        if(screenView && self.currentStreamView && ![screenView.value isEqualToString:screenView.value]) {
            oldScreenView = screenView;
        }
    }else{
        oldScreenView = [self screenStreamView];
    }
   
    
    
    if(oldScreenView) {
       CGPoint point = [self.participantStreamBox convertPoint:oldScreenView.lim_origin toView:self.otherParticipantStreamBox];
        oldScreenView.lim_origin = point;
    }
    if(newScreenView) {
        newScreenView.frame = CGRectMake(0.0f, 0.0f, self.participantStreamBox.lim_width, self.participantStreamBox.lim_height - self.otherParticipantStreamBox.lim_height);
    }
   
    
  
    
//    if(![self hasScreenUser]) {
//        WKRTCStreamView *oldScreenView = [self screenStreamView];
//        if(oldScreenView) {
//            [self.participantStreamBox convertPoint:CGPointMake(oldScreenView.lim_origin.x, <#CGFloat y#>) toView:self.otherParticipantStreamBox];
//        }
//    }
    
  
   
}

-(void) layoutForHasScreen:(NSArray<WKRTCStreamView*>*)streamViews {
    if(streamViews && streamViews.count>0) {
        UIView *preView;
        for (WKRTCStreamView *subView in streamViews) {
            if([subView.value isEqualToString:self.screenUID]) {
                continue;
            }
            if(preView) {
                subView.frame = CGRectMake(preView.lim_right, 0.0f, minWindowUserSize.width, minWindowUserSize.height);
            }else{
                subView.frame = CGRectMake(0.0f, 0.0f, minWindowUserSize.width, minWindowUserSize.height);
            }
            preView = subView;
            
            [subView layoutSubviews];
        }
        if(preView) {
            [self.otherParticipantStreamBox setContentSize:CGSizeMake(preView.lim_right, self.otherParticipantStreamBox.lim_height)];
        }
       
    }
}

-(void) layoutForNoHasScreen:(NSArray<WKRTCStreamView*>*)streamViews {
    NSInteger participantCount = streamViews.count;
   
    if(participantCount>0) {
        CGSize itemSize;
        NSInteger totalCol = 0;
        if(participantCount<=4) {
            itemSize = CGSizeMake(self.frame.size.width/2.0f, self.frame.size.width/2.0f);
            totalCol = 2;
        }else {
            itemSize = CGSizeMake(self.frame.size.width/3.0f, self.frame.size.width/3.0f);
            totalCol = 3;
        }
        NSInteger row = 0;
        NSInteger col = 0;
        for (NSInteger i=0; i<participantCount; i++) {
            UIView *subView = streamViews[i];
            if(i%totalCol == 0) {
                row++;
                col = 1;
            }
            subView.frame = CGRectMake((col-1)*itemSize.width, (row-1)*itemSize.height, itemSize.width, itemSize.height);
            
            col++;
            [subView layoutSubviews];
        }
    }
    [self.otherParticipantStreamBox setContentSize:CGSizeMake(self.lim_width, self.otherParticipantStreamBox.lim_height)];
}

-(NSArray<WKRTCStreamView*>*) streamViews {
    NSMutableArray<WKRTCStreamView*> *views = [NSMutableArray array];
    
    for (WKRTCParticipant *pt in self.participants) {
        WKRTCStreamView *screenView =  [self screenStreamView];
        if(screenView) {
            if([pt.uid isEqualToString:screenView.value]) {
                [views addObject:screenView];
                continue;
            }
        }
        for (UIView *view in self.otherParticipantStreamBox.subviews) {
            if([view isKindOfClass:[WKRTCStreamView class]]) {
                WKRTCStreamView *streamV = (WKRTCStreamView*)view;
                if([pt.uid isEqualToString:streamV.value]) {
                    [views addObject:(WKRTCStreamView*)view];
                    break;
                }
            }
        }
    }

    return views;
}

-(WKRTCStreamView*) screenStreamView {
    for (UIView *view in self.participantStreamBox.subviews) {
        if([view isKindOfClass:[WKRTCStreamView class]]) {
            return (WKRTCStreamView*)view;
        }
    }
    return nil;
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
    self.navigation.timeLbl.text = timeStr;
    [self.navigation.timeLbl sizeToFit];
    
    self.timeLbl.text = timeStr;
    [self.timeLbl sizeToFit];
    
}

-(void) showByViewType {
    if(self.viewType == WKRTCViewTypeResponse && (self.status != WKRTCStatusStartTalking && self.status != WKRTCStatusConnecting)) {
        self.responseView.hidden = NO;
        self.navigation.hidden = YES;
        self.participantStreamBox.hidden = YES;
        self.bottom.hidden = YES;
    }else {
        self.responseView.hidden = YES;
        
        self.navigation.hidden = NO;
        self.participantStreamBox.hidden = NO;
        self.bottom.hidden = NO;
    }
}

- (UIView *)participantStreamBox {
    if(!_participantStreamBox) {
        _participantStreamBox = [[UIView alloc] init];
//        _participantStreamBox.backgroundColor = [UIColor redColor];
    }
    return _participantStreamBox;
}

- (UIScrollView *)otherParticipantStreamBox {
    if(!_otherParticipantStreamBox) {
        _otherParticipantStreamBox = [[UIScrollView alloc] init];
//        _otherParticipantStreamBox.backgroundColor = [UIColor blueColor];
    }
    return _otherParticipantStreamBox;
}

- (UIImageView *)talkingIconImgView {
    if(!_talkingIconImgView) {
        _talkingIconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
        _talkingIconImgView.alpha = 0.0f;
        _talkingIconImgView.image = LImage(@"talking_icon");
    }
    return _talkingIconImgView;
}

- (UILabel *)timeLbl {
    if(!_timeLbl) {
        _timeLbl = [[UILabel alloc] init];
        _timeLbl.font = [WKApp.shared.config appFontOfSize:15.0f];
        _timeLbl.textColor = WKApp.shared.config.themeColor;
        
    }
    return _timeLbl;
}

- (WKRTCConferenceResponseView *)responseView {
    if(!_responseView) {
        _responseView = [[WKRTCConferenceResponseView alloc] init];
        _responseView.hidden = YES;
        __weak typeof(self) weakSelf = self;
        [_responseView setOnAnswer:^{
            if(weakSelf.onAccepted) {
                weakSelf.onAccepted();
            }
            
        }];
        [_responseView setOnHangup:^{
            if(weakSelf.onHangup) {
                weakSelf.onHangup();
            }
            
        }];
    }
    return _responseView;
}

- (WKRTCConferenceNavigation *)navigation {
    if(!_navigation) {
        _navigation = [[WKRTCConferenceNavigation alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, 80.0f)];
        __weak typeof(self) weakSelf = self;
        _navigation.onMin = ^{
            [weakSelf minPressed];
        };
        
        _navigation.onAdd = ^{
            if(weakSelf.onAddParticipant) {
                weakSelf.onAddParticipant(^(NSArray<NSString *> * _Nonnull participants) {
                    if(participants && participants.count>0) {
                        for (NSString *participant in participants) {
                            WKRTCParticipant *p = [[WKRTCParticipant alloc] initWithUID:participant];
                            p.role = WKRTCParticipantRoleInviter;
                            [weakSelf.participants addObject:p];
                            [weakSelf addParticipant:participant];
                        }
                        [weakSelf layoutSubviews];
                       
                    }
                });
            }
        };
    }
    return _navigation;
}



- (WKRTCConferenceBottom *)bottom {
    if(!_bottom) {
        _bottom = [[WKRTCConferenceBottom alloc] init];
        _bottom.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1f];
        
        __weak typeof(self) weakSelf = self;
        _bottom.onHangup = ^{
            if(weakSelf.onHangup) {
                weakSelf.onHangup();
            }
        };
        __weak typeof(_bottom) weakSelfBottom = _bottom;
        _bottom.onArrow = ^{
            [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
                weakSelfBottom.changeToSmall = !weakSelfBottom.changeToSmall;
                [weakSelfBottom layoutSubviews];
                [weakSelf layoutSubviews];
            }];
        };
        
        _bottom.onCameraSwitch = ^(BOOL on) {
            if(weakSelf.onSwitch) {
                weakSelf.onSwitch();
            }
        };
        
        _bottom.onHandsFree = ^(BOOL on) {
            if(weakSelf.onHandsFree) {
                weakSelf.onHandsFree(on);
            }
        };
        
        _bottom.onMute = ^(BOOL on) {
            if(weakSelf.onMute) {
                weakSelf.onMute(on);
            }
        };
        
    }
    return _bottom;
}

// 缩小
-(void) minPressed {
    [self zoomOut];
}

// 放大
-(void) zoomInTapPressed {
    [self zoomIn];
}

// 缩小
-(void) zoomOut {
    [self zoomOut:YES];
}

// 放大
-(void) zoomIn {
    self.isZoomOut = NO;
    [self removeGestureRecognizer:self.minPanTap];
    [self removeGestureRecognizer:self.zoomInTap];
    
    [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
        [self zoomLayoutFrame];
        [self layoutSubviews];
    }];
}

-(void) zoomOut:(BOOL)animation{
    self.isZoomOut = YES;
    
    [self addGestureRecognizer:self.minPanTap];
    [self addGestureRecognizer:self.zoomInTap];
    
    [UIView animateWithDuration:WKApp.shared.config.defaultAnimationDuration animations:^{
        [self zoomLayoutFrame];
        [self layoutSubviews];
    }];
}

-(void) zoomLayoutFrame {
    CGFloat safeTop = 0.0f;
    safeTop = self.window.safeAreaInsets.top;
    CGSize minSize =  CGSizeMake(80.0f, 80.0f);
    CGPoint minWindowPoint =  CGPointMake(WKScreenWidth - minSize.width - WKMinWindowRightSpace, safeTop+WKMinWindowTopSpace);
    
    
    if(self.isZoomOut) { // 缩小
        if(CGPointEqualToPoint(self.voiceMinPoint, CGPointZero)) {
            self.voiceMinPoint = CGPointMake(WKScreenWidth - minSize.width - WKMinWindowRightSpace, safeTop+WKMinWindowTopSpace);
        }
        minWindowPoint = self.voiceMinPoint;
        if(!CGPointEqualToPoint(self.lim_origin, CGPointZero)) {
            minWindowPoint = self.lim_origin;
        }
        self.frame = CGRectMake(minWindowPoint.x, minWindowPoint.y, minSize.width, minSize.height);
    }else {
        self.voiceMinPoint = self.lim_origin;
        self.frame = [UIScreen mainScreen].bounds;
    }
    
    
    if(self.isZoomOut) {
        self.backgroundColor = WKApp.shared.config.cellBackgroundColor;
        self.layer.cornerRadius = 8.0f;
        self.layer.shadowOffset = CGSizeMake(2, 2);
        self.layer.shadowOpacity = 0.1f;
        self.layer.shadowRadius = 2;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
    }else{
        self.backgroundColor = [UIColor blackColor];
        self.layer.cornerRadius = 0.0f;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowOpacity = 0.0f;
        self.layer.shadowRadius = 0;
        self.layer.shadowColor = [UIColor clearColor].CGColor;
    }
    
}

- (UITapGestureRecognizer *)zoomInTap {
    if(!_zoomInTap) {
        _zoomInTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomInTapPressed)];
    }
    return _zoomInTap;
}

- (UIPanGestureRecognizer *)minPanTap {
    if(!_minPanTap) {
        _minPanTap = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(minPanPressed:)];
    }
    return _minPanTap;
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

-(void) end {
    if(self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)dealloc {
    NSLog(@"WKRTCConferenceView dealloc");
    
}

- (NSArray<NSString *> *)participantUIDs {
    NSMutableArray<NSString*> *participants = [NSMutableArray array];
    NSArray<WKRTCStreamView*> *streamViews =  [self streamViews];
    if(streamViews && streamViews.count>0) {
        for (WKRTCStreamView *streamView in streamViews) {
            [participants addObject:streamView.value];
        }
    }
    return participants;
}

@synthesize onAccepted;

@synthesize onHangup;

@synthesize onSwitch;

@synthesize status;

@synthesize onHandsFree;

@synthesize onMute;

@synthesize onAddParticipant;

@synthesize participantUIDs;



@end
