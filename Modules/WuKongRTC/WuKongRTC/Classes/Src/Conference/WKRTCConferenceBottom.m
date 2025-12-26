//
//  WKRTCConferenceBottom.m
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import "WKRTCConferenceBottom.h"
#import "WKRTCActionButton.h"
#import <WuKongBase/WuKongBase.h>

#define defaultHeight 250.0f

@interface WKRTCConferenceBottom ()

@property(nonatomic,strong) WKMuteActionButton *muteBtn; // 静音
@property(nonatomic,strong) WKHandsFreeActionButton *handsfreeBtn; // 免提
@property(nonatomic,strong) WKCameraSwitcActionButton *cameraSwitchBtn; // 摄像头切换

@property(nonatomic,strong) WKHangupActionButton *hangupBtn; // 挂断

@property(nonatomic,strong) UIButton *arrowBtn; // 箭头

@end

@implementation WKRTCConferenceBottom

- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, defaultHeight)];
    if (self) {
        [self addSubview:self.muteBtn];
        [self addSubview:self.handsfreeBtn];
        [self addSubview:self.cameraSwitchBtn];
        
        [self addSubview:self.hangupBtn];
        
        [self addSubview:self.arrowBtn];
        
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 20.0f;
    }
    return self;
}

- (void)setChangeToSmall:(BOOL)changeToSmall {
    _changeToSmall = changeToSmall;
    if(changeToSmall) {
//        self.lim_height = 120.0f;
        self.muteBtn.changeToSmall = true;
        self.handsfreeBtn.changeToSmall = true;
        self.cameraSwitchBtn.changeToSmall = true;
        self.hangupBtn.changeToSmall = true;
    }else{
//        self.lim_height = 300.0f;
        self.muteBtn.changeToSmall = false;
        self.handsfreeBtn.changeToSmall = false;
        self.cameraSwitchBtn.changeToSmall = false;
        
        self.hangupBtn.changeToSmall = false;
        
       
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if(self.changeToSmall) {
        self.lim_height = 120.0f;
        CGFloat leftSpace = 120.0f;
        CGFloat contentWidth = self.lim_width - leftSpace;
        CGFloat contentHeight = self.lim_height - [self safeBottom];
        CGFloat space = (contentWidth - self.muteBtn.lim_width - self.handsfreeBtn.lim_width - self.cameraSwitchBtn.lim_width - self.hangupBtn.lim_width)/3.0f;
        
        self.arrowBtn.transform = CGAffineTransformMakeRotation(M_PI);
       
        
        self.muteBtn.lim_left = leftSpace - 20.0f;
        self.muteBtn.lim_top = contentHeight/2.0f - self.muteBtn.lim_height/2.0f;
        
        self.handsfreeBtn.lim_left = self.muteBtn.lim_right + space;
        self.handsfreeBtn.lim_top =  contentHeight/2.0f - self.handsfreeBtn.lim_height/2.0f;
        
        self.cameraSwitchBtn.lim_left = self.handsfreeBtn.lim_right + space;
        self.cameraSwitchBtn.lim_top =  contentHeight/2.0f - self.cameraSwitchBtn.lim_height/2.0f;
        
        self.hangupBtn.lim_left = self.cameraSwitchBtn.lim_right + space;
        self.hangupBtn.lim_top = contentHeight/2.0f - self.hangupBtn.lim_height/2.0f;
        
    }else{
        CGFloat topSpace = 20.0f;
        self.lim_height = defaultHeight;
        CGFloat space = (self.lim_width - self.muteBtn.lim_width - self.handsfreeBtn.lim_width - self.cameraSwitchBtn.lim_width)/4.0f;
        
        self.muteBtn.lim_left = space;
        self.muteBtn.lim_top = topSpace;
        
        self.handsfreeBtn.lim_left = self.muteBtn.lim_right + space;
        self.handsfreeBtn.lim_top = self.muteBtn.lim_top;
        
        self.cameraSwitchBtn.lim_left = self.handsfreeBtn.lim_right + space;
        self.cameraSwitchBtn.lim_top = self.muteBtn.lim_top;
        
        self.hangupBtn.lim_top = self.muteBtn.lim_bottom + 20.0f;
        self.hangupBtn.lim_centerX_parent = self;
        
        self.arrowBtn.transform = CGAffineTransformMakeRotation(0);
    }
    
    self.arrowBtn.lim_left = 40.0f;
    self.arrowBtn.lim_top = self.lim_height - self.arrowBtn.lim_height - [self safeBottom] - 25.0f;
    
   
}

-(CGFloat) safeBottom {
    return UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
}

- (WKMuteActionButton *)muteBtn {
    if(!_muteBtn) {
        _muteBtn = [[WKMuteActionButton alloc] init];
        __weak typeof(self) weakSelf = self;
        _muteBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onMute) {
                weakSelf.onMute(on);
            }
        };
    }
    return _muteBtn;
}

- (WKHandsFreeActionButton *)handsfreeBtn {
    if(!_handsfreeBtn) {
        _handsfreeBtn = [[WKHandsFreeActionButton alloc] init];
        _handsfreeBtn.on = YES;
        __weak typeof(self) weakSelf = self;
        _handsfreeBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onHandsFree) {
                weakSelf.onHandsFree(on);
            }
        };
    }
    return _handsfreeBtn;
}
- (UIButton *)arrowBtn {
    if(!_arrowBtn) {
        _arrowBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
        _arrowBtn.layer.masksToBounds = YES;
        _arrowBtn.layer.cornerRadius = _arrowBtn.lim_height/2.0f;
        _arrowBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.1f];
        [_arrowBtn setImage:LImage(@"icon_arrow") forState:UIControlStateNormal];
        [_arrowBtn setImageEdgeInsets:UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f)];
        [_arrowBtn addTarget:self action:@selector(arrowPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _arrowBtn;
}

-(void) arrowPressed {
    if(self.onArrow) {
        self.onArrow();
    }
}

- (WKHangupActionButton *)hangupBtn {
    if(!_hangupBtn) {
        _hangupBtn = [[WKHangupActionButton alloc] init];
        _hangupBtn.style2 = true;
        __weak typeof(self) weakSelf = self;
        _hangupBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onHangup) {
                weakSelf.onHangup();
            }
        };
    }
    return _hangupBtn;
}

- (WKCameraSwitcActionButton *)cameraSwitchBtn {
    if(!_cameraSwitchBtn) {
        _cameraSwitchBtn = [[WKCameraSwitcActionButton alloc] init];
        __weak typeof(self) weakSelf = self;
        _cameraSwitchBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onCameraSwitch) {
                weakSelf.onCameraSwitch(on);
            }
        };
    }
    return _cameraSwitchBtn;
}

@end
