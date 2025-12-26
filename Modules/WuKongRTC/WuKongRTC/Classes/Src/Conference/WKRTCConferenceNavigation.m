//
//  WKRTCConferenceNavigation.m
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import "WKRTCConferenceNavigation.h"
#import <WuKongBase/WuKongBase.h>
@interface WKRTCConferenceNavigation ()


@property(nonatomic,strong) UIButton *minBtn;

@property(nonatomic,strong) UIButton *addBtn;

@end

@implementation WKRTCConferenceNavigation

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        self.backgroundColor = [UIColor redColor];
        [self addSubview:self.timeLbl];
        [self addSubview:self.minBtn];
        [self addSubview:self.addBtn];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.timeLbl.lim_centerX_parent = self;
    self.minBtn.lim_left = 15.0f;
    self.minBtn.lim_top =  [self safeTop];
    
    self.addBtn.lim_left = self.lim_width - self.addBtn.lim_width - 15.0f;
    self.addBtn.lim_top = self.minBtn.lim_top;
}

- (UILabel *)timeLbl {
    if(!_timeLbl) {
        _timeLbl = [[UILabel alloc] init];
        _timeLbl.font = [WKApp.shared.config appFontOfSize:16.0f];
        _timeLbl.text = @"等待接听";
        _timeLbl.textColor = [UIColor whiteColor];
        [_timeLbl sizeToFit];
        _timeLbl.lim_top =  [self safeTop];
    }
    return _timeLbl;
}

-(CGFloat) safeTop {
   return UIApplication.sharedApplication.keyWindow.safeAreaInsets.top;
}
- (UIButton *)minBtn {
    if(!_minBtn) {
        _minBtn = [[UIButton alloc] init];
        [_minBtn setImage:LImage(@"call_min") forState:UIControlStateNormal];
        [_minBtn sizeToFit];
        
        [_minBtn addTarget:self action:@selector(minPressed) forControlEvents:UIControlEventTouchUpInside];
       
    }
    return _minBtn;
}

-(void) minPressed {
    if(self.onMin) {
        self.onMin();
    }
}

- (UIButton *)addBtn {
    if(!_addBtn) {
        _addBtn = [[UIButton alloc] init];
        [_addBtn setImage:LImage(@"add_participant") forState:UIControlStateNormal];
        [_addBtn sizeToFit];
        [_addBtn addTarget:self action:@selector(addPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addBtn;
}

-(void) addPressed {
    if(self.onAdd) {
        self.onAdd();
    }
}

@end
