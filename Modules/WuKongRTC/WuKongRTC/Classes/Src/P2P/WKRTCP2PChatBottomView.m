//
//  WKRTCP2PChatBottomView.m
//  WuKongRTC
//
//  Created by tt on 2022/10/4.
//

#import "WKRTCP2PChatBottomView.h"

#import <WuKongBase/WuKongBase.h>
#import <DGActivityIndicatorView/DGActivityIndicatorView.h>
@interface WKRTCP2PChatBottomView ()

@end

@implementation WKRTCP2PChatBottomView

-(instancetype) initWithFrame:(CGRect)frame status:(WKRTCStatus)status viewType:(WKRTCViewType)viewType callType:(WKRTCCallType)callType {
    self = [super initWithFrame:frame];
    if (self) {
        self.status = status;
        self.viewType = viewType;
        self.callType = callType;
        
        [self addSubview:self.hangupBtn];
        [self addSubview:self.answerBtn];
        [self addSubview:self.cameraSwitchBtn];
        [self addSubview:self.handsFreeBtn];
        [self addSubview:self.muteBtn];
        [self addSubview:self.cameraToggleBtn];
        
        if(self.viewType == WKRTCViewTypeCall) {
            self.answerBtn.hidden = YES;
        }
//        self.backgroundColor = [UIColor blueColor];
    }
    return self;
}

- (void)setStatus:(WKRTCStatus)status {
    _status = status;
}



- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat space = (self.lim_width - self.cameraSwitchBtn.lim_width - self.handsFreeBtn.lim_width - self.muteBtn.lim_width)/4.0f;
    
    if(self.callType == WKRTCCallTypeAudio) {
        self.cameraSwitchBtn.lim_left = space;
        self.handsFreeBtn.lim_left = self.cameraSwitchBtn.lim_right + space;
        self.muteBtn.lim_left = self.handsFreeBtn.lim_right + space;
        self.cameraSwitchBtn.on = NO;
    }else{
        self.cameraSwitchBtn.lim_left = space;
        self.muteBtn.lim_left = self.cameraSwitchBtn.lim_right + space;
        self.cameraToggleBtn.lim_left = self.muteBtn.lim_right + space;
        self.cameraSwitchBtn.on = YES;
    }

    if(self.callType == WKRTCCallTypeAudio) {
        [self layoutAudio];
    }else{
        [self layoutVideo];
    }
}

-(void) layoutAudio {
    CGFloat buttonBottomSpace = 20.0f + [self safeBottom];
    if([self talking]) {
        self.cameraSwitchBtn.alpha = 1.0f;
        self.handsFreeBtn.alpha = 1.0f;
        self.muteBtn.alpha = 1.0f;
        
        self.cameraToggleBtn.alpha = 0.0f;
        
        self.hangupBtn.titleLbl.text = @"挂断";
        [self.hangupBtn.titleLbl sizeToFit];
    }else{
        if(self.viewType == WKRTCViewTypeCall) {
            self.hangupBtn.lim_centerX_parent = self;
            self.hangupBtn.lim_top = self.lim_height - self.hangupBtn.lim_height - buttonBottomSpace;
        }else {
            CGFloat space = (self.lim_width - self.answerBtn.lim_width - self.hangupBtn.lim_width)/3;
            
            self.hangupBtn.lim_left = space - 10.0f;
            self.hangupBtn.lim_top = self.lim_height - self.hangupBtn.lim_height - buttonBottomSpace;
            
            self.answerBtn.lim_left = self.hangupBtn.lim_right + space + 10.0f;
            self.answerBtn.lim_top = self.lim_height - self.answerBtn.lim_height - buttonBottomSpace;
            if(self.status == WKRTCStatusConnecting) {
                self.answerBtn.alpha = 0.0f;
                self.hangupBtn.lim_centerX_parent  = self;
                
                self.hangupBtn.style2 = true;
                self.hangupBtn.titleLbl.text = @"取消";
                [self.hangupBtn.titleLbl sizeToFit];
                
            }
        }
    }
}

-(void) layoutVideo {
    CGFloat buttonBottomSpace = 20.0f + [self safeBottom];
    
    if([self talking]) {
        self.cameraSwitchBtn.alpha = 1.0f;
        self.muteBtn.alpha = 1.0f;
        self.cameraToggleBtn.alpha = 1.0f;
        
        self.handsFreeBtn.alpha = 0.0f;
        
        self.hangupBtn.titleLbl.text = @"挂断";
        [self.hangupBtn.titleLbl sizeToFit];
    }else{
        if(self.viewType == WKRTCViewTypeCall) {
            self.hangupBtn.lim_centerX_parent = self;
            self.hangupBtn.lim_top = self.lim_height - self.hangupBtn.lim_height - buttonBottomSpace;
        }else{
            CGFloat space = (self.lim_width - self.answerBtn.lim_width - self.hangupBtn.lim_width)/3;
            
            self.hangupBtn.lim_left = space - 10.0f;
            self.hangupBtn.lim_top = self.lim_height - self.hangupBtn.lim_height - buttonBottomSpace;
            
            self.answerBtn.lim_left = self.hangupBtn.lim_right + space + 10.0f;
            self.answerBtn.lim_top = self.lim_height - self.answerBtn.lim_height - buttonBottomSpace;
            
            if(self.status == WKRTCStatusConnecting) {
                self.answerBtn.alpha = 0.0f;
                self.hangupBtn.lim_centerX_parent  = self;
                
                self.hangupBtn.style2 = true;
                self.hangupBtn.titleLbl.text = @"取消";
                [self.hangupBtn.titleLbl sizeToFit];
            }
        }
    }
    
   
}


-(BOOL) talking {
    return self.status == WKRTCStatusStartTalking || self.status == WKRTCStatusP2PAccepted;
}

-(CGFloat) safeBottom {
    return  UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
}

- (WKHangupActionButton *)hangupBtn {
    if(!_hangupBtn) {
        _hangupBtn = [[WKHangupActionButton alloc] init];
        if(self.viewType == WKRTCViewTypeCall) {
            _hangupBtn.style2 = true;
            _hangupBtn.titleLbl.text = @"取消";
            [ _hangupBtn.titleLbl sizeToFit];
        }else {
            _hangupBtn.titleLbl.text = @"拒绝";
            [ _hangupBtn.titleLbl sizeToFit];
        }
        __weak typeof(self) weakSelf = self;
        _hangupBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onHangup) {
                weakSelf.onHangup();
            }
        };
        [_hangupBtn layoutSubviews];
    }
    return _hangupBtn;
}

- (WKAnswerActionButton *)answerBtn {
    if(!_answerBtn) {
        _answerBtn = [[WKAnswerActionButton alloc] init];
        __weak typeof(self) weakSelf = self;
        _answerBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onAnswer) {
                weakSelf.onAnswer();
            }
        };
    }
    return _answerBtn;
}

- (WKCameraSwitcActionButton *)cameraSwitchBtn {
    if(!_cameraSwitchBtn) {
        _cameraSwitchBtn = [[WKCameraSwitcActionButton alloc] init];
        _cameraSwitchBtn.alpha = 0.0f;
        __weak typeof(self) weakSelf = self;
        _cameraSwitchBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onCameraSwitch) {
                weakSelf.onCameraSwitch(on);
            }
        };
    }
    return _cameraSwitchBtn;
}

- (WKHandsFreeActionButton *)handsFreeBtn {
    if(!_handsFreeBtn) {
        _handsFreeBtn = [[WKHandsFreeActionButton alloc] init];
        _handsFreeBtn.alpha = 0.0f;
        __weak typeof(self) weakSelf = self;
        _handsFreeBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onHandsFree) {
                weakSelf.onHandsFree(on);
            }
        };
    }
    return _handsFreeBtn;
}

- (WKMuteActionButton *)muteBtn {
    if(!_muteBtn) {
        _muteBtn = [[WKMuteActionButton alloc] init];
        _muteBtn.alpha = 0.0f;
        __weak typeof(self) weakSelf = self;
        _muteBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onMute) {
                weakSelf.onMute(on);
            }
        };
    }
    return _muteBtn;
}

- (WKCameraToggleActionButton *)cameraToggleBtn {
    if(!_cameraToggleBtn) {
        _cameraToggleBtn = [[WKCameraToggleActionButton alloc] init];
        _cameraToggleBtn.alpha = 0.0f;
        __weak typeof(self) weakSelf = self;
        _cameraToggleBtn.onSwitch = ^(BOOL on) {
            if(weakSelf.onCameraToggle) {
                weakSelf.onCameraToggle(on);
            }
        };
    }
    return _cameraToggleBtn;
}

@end
