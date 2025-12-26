//
//  WKP2PChatUserView.m
//  WuKongRTC
//
//  Created by tt on 2022/10/5.
//

#import "WKP2PChatUserView.h"
#import <WuKongBase/WuKongBase.h>

@interface WKP2PChatUserView ()

@property(nonatomic,assign) WKRTCViewType viewType;



@end

@implementation WKP2PChatUserView

-(instancetype) initWithViewType:(WKRTCViewType)viewType callType:(WKRTCCallType)callType {
    CGRect frame = CGRectMake(0.0f, 0.0f, WKScreenWidth, 200.0f);
    if(callType == WKRTCCallTypeVideo) {
        frame = CGRectMake(0.0f, 0.0f, 160.0f, 60.0f);
    }
    self = [super initWithFrame:frame];
    if(self) {
        self.viewType = viewType;
        self.callType = callType;
        [self addSubview:self.userAvatarImgView];
        [self addSubview:self.nameLbl];
        [self addSubview:self.statusLbl];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat nameTopSpace = 10.0f;
    CGFloat statusTopSpace = 10.0f;
    
    self.userAvatarImgView.layer.masksToBounds = YES;
    if(self.callType == WKRTCCallTypeAudio) {
        
        self.userAvatarImgView.lim_top = 0.0f;
        self.userAvatarImgView.lim_size = CGSizeMake(120.0f, 120.0f);
        self.userAvatarImgView.lim_centerX_parent = self;
        self.userAvatarImgView.layer.cornerRadius = 20.0f;
        
        self.nameLbl.lim_centerX_parent = self;
        self.nameLbl.lim_top = self.userAvatarImgView.lim_bottom + nameTopSpace;
        
        self.statusLbl.lim_centerX_parent = self;
        self.statusLbl.lim_top = self.nameLbl.lim_bottom + statusTopSpace;
        
        self.lim_height = self.userAvatarImgView.lim_height + self.nameLbl.lim_height + nameTopSpace + self.statusLbl.lim_height + statusTopSpace;
    }else{
        CGFloat space = 10.0f;
        
        self.userAvatarImgView.lim_size = CGSizeMake(40.0f, 40.0f);
        self.userAvatarImgView.layer.cornerRadius = self.userAvatarImgView.lim_height/2.0f;
        self.userAvatarImgView.lim_centerY_parent = self;
        self.userAvatarImgView.lim_left = space;
        
        self.nameLbl.lim_left = self.userAvatarImgView.lim_right + space;
        self.nameLbl.lim_top = space;
        
        self.statusLbl.lim_top = self.nameLbl.lim_bottom + 5.0f;
        self.statusLbl.lim_left = self.nameLbl.lim_left;
        
        CGFloat w = MAX(self.statusLbl.lim_right + space+10, self.nameLbl.lim_right + space);
        self.lim_width = w;
        self.layer.cornerRadius = self.lim_height/2.0f;
        
        self.lim_height = 60.0f;
        
    }
    
}

- (void)setStatus:(WKRTCStatus)status {
    _status = status;
    if(status == WKRTCStatusConnecting) {
        self.statusLbl.text = @"连接中...";
        [self.statusLbl sizeToFit];
    }
}

- (void)setCallType:(WKRTCCallType)callType {
    _callType = callType;
    if(self.callType == WKRTCCallTypeVideo) {
        self.statusLbl.font = [WKApp.shared.config appFontOfSize:14.0f];
        [self.statusLbl sizeToFit];
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f];
    }else{
        self.statusLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
        [self.statusLbl sizeToFit];
        self.backgroundColor =  [UIColor clearColor];
    }
    
}

- (UIImageView *)userAvatarImgView {
    if(!_userAvatarImgView) {
        _userAvatarImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _userAvatarImgView;
}

- (UILabel *)nameLbl {
    if(!_nameLbl) {
        _nameLbl = [[UILabel alloc] init];
        _nameLbl.textColor = [UIColor whiteColor];
        _nameLbl.font = [WKApp.shared.config appFontOfSizeSemibold:30.0f];
        
        if(self.callType == WKRTCCallTypeVideo) {
            _nameLbl.font = [WKApp.shared.config appFontOfSizeSemibold:16.0f];
        }
    }
    return _nameLbl;
}

- (UILabel *)statusLbl {
    if(!_statusLbl) {
        _statusLbl = [[UILabel alloc] init];
        _statusLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
        _statusLbl.textColor = [UIColor whiteColor];
       
    }
    return _statusLbl;
}


@end

