//
//  WKRTCActionButton.m
//  WuKongRTC
//
//  Created by tt on 2021/5/1.
//

#import "WKRTCActionButton.h"
#import <WuKongBase/WuKongBase.h>
@import  WuKongBase.Swift;
@interface WKRTCActionButton ()




@property(nonatomic,copy) NSString *onIcon;
@property(nonatomic,copy) NSString *offIcon;


@end

@implementation WKRTCActionButton

-(instancetype) initWithIcon:(NSString*)icon onIcon:(NSString*)onicon title:(NSString*)title {
    self = [super initWithFrame:CGRectMake(0.0f, 0.0f, 65.0f, 100.0f)];
    if(self) {
        [self addSubview:self.iconImgView];
        [self addSubview:self.titleLbl];
        if(icon) {
            [self.iconImgView setImage:[self imageName:icon]];
        }
        [self.titleLbl setText:title];
        self.offIcon = icon;
        self.onIcon = onicon;
        [self.titleLbl sizeToFit];
        
        self.backgroundColor = [UIColor  clearColor];
        
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

-(void) onTap {
    [self setOn:!self.on];
    
    if(self.onSwitch) {
        self.onSwitch(self.on);
    }
}

- (void)setChangeToSmall:(BOOL)changeToSmall {
    _changeToSmall = changeToSmall;
    if(changeToSmall) {
        self.lim_size = CGSizeMake(40.0f, 40.0f);
    }else{
        self.lim_size = CGSizeMake(65.0f, 100.0f);
    }
    [self layoutSubviews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if(self.changeToSmall) {
       
        self.iconImgView.lim_size = self.lim_size;
        self.titleLbl.alpha = 0.0f;
        self.iconImgView.lim_centerX_parent = self;
        self.iconImgView.lim_centerY_parent = self;
    }else{
        
        self.iconImgView.lim_size = CGSizeMake(self.lim_width, self.lim_width);
        self.iconImgView.lim_centerX_parent = self;
        self.titleLbl.alpha = 1.0f;
        self.titleLbl.lim_centerX_parent = self;
        self.titleLbl.lim_top = self.iconImgView.lim_bottom + 10.0f;
    }
    
   
    
}

- (void)setOn:(BOOL)on {
    _on = on;
    if(on) {
        if(self.onIcon) {
            [self.iconImgView setImage:[self imageName:self.onIcon]];
        }
        
    }else {
        if(self.offIcon) {
            [self.iconImgView setImage:[self imageName:self.offIcon]];
        }
    }
    
}


- (UIImageView *)iconImgView {
    if(!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.lim_width,  self.lim_width)];
//        _iconImgView.layer.masksToBounds = YES;
//        _iconImgView.layer.cornerRadius = _iconImgView.lim_height/2.0f;
    }
    return _iconImgView;
}

- (UILabel *)titleLbl {
    if(!_titleLbl) {
        _titleLbl = [[UILabel alloc] init];
        [_titleLbl setFont:[[WKApp shared].config appFontOfSize:15.0f]];
        [_titleLbl setTextColor:[UIColor whiteColor]];
    }
    return _titleLbl;
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRTC"];
}

@end

@implementation WKMuteActionButton

- (instancetype)init
{
    self = [super initWithIcon:@"call_mute_off" onIcon:@"call_mute_on" title:LLang(@"静音")];
    if (self) {
      
    }
    return self;
}

@end

@implementation WKHandsFreeActionButton

- (instancetype)init
{
    self = [super initWithIcon:@"call_handsfree_off" onIcon:@"call_handsfree_on" title:LLang(@"免提")];
    if (self) {
      
    }
    return self;
}

@end

@implementation WKCameraSwitcActionButton

- (instancetype)init
{
    self = [super initWithIcon:@"switch_camera_off" onIcon:@"switch_camera_on" title:LLang(@"切换至视频")];
    if (self) {
      
    }
    return self;
}

- (void)setOn:(BOOL)on {
    [super setOn:on];
    if(on) {
        self.titleLbl.text = LLang(@"切换至语音");
    }else{
        self.titleLbl.text = LLang(@"切换至视频");
    }
    [self.titleLbl sizeToFit];
}

@end

@implementation WKCameraToggleActionButton

- (instancetype)init
{
    self = [super initWithIcon:@"camera_switch_on" onIcon:@"camera_switch_on" title:LLang(@"摄像头")];
    if (self) {
      
    }
    return self;
}

@end

@interface WKAnswerActionButton ()

@property(nonatomic,strong) UIView *imageBoxView;

@end

@implementation WKAnswerActionButton

- (instancetype)init
{
    self = [super initWithIcon:@"answer" onIcon:nil title:LLang(@"接听")];
    if (self) {
        self.imageBoxView.backgroundColor = [UIColor colorWithRed:112.0f/255.0f green:180.0f/255.0f blue:76.0f/255.0f alpha:1.0f];
        [self addSubview:self.imageBoxView];
        [self.imageBoxView addSubview:self.iconImgView];
        
        self.iconImgView.lim_size = CGSizeMake(32.0f, 32.0f);
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.iconImgView.lim_size = CGSizeMake(32.0f, 32.0f);
    
    self.imageBoxView.lim_centerX_parent = self;
    
    self.iconImgView.lim_centerY_parent = self.imageBoxView;
    self.iconImgView.lim_centerX_parent = self.imageBoxView;
    
    self.titleLbl.lim_top = self.imageBoxView.lim_bottom + 10.0f;
}

- (UIView *)imageBoxView {
    if(!_imageBoxView) {
        _imageBoxView = [[UIView alloc] initWithFrame:self.iconImgView.bounds];
        _imageBoxView.layer.masksToBounds = YES;
        _imageBoxView.layer.cornerRadius = _imageBoxView.lim_height/2.0f;
    }
    return _imageBoxView;
}

@end

@interface WKHangupActionButton ()

@property(nonatomic,assign) CGRect oldFrame;
@property(nonatomic,assign) CGRect oldIconImgFrame;

@property(nonatomic,strong) UIView *imageBoxView;

@end

@implementation WKHangupActionButton

- (instancetype)init
{
    self = [super initWithIcon:@"hangup" onIcon:nil title:LLang(@"挂断")];
    if (self) {
        self.oldFrame = self.frame;
        self.oldIconImgFrame = self.iconImgView.frame;
        
        [self addSubview:self.imageBoxView];
        [self.imageBoxView addSubview:self.iconImgView];
        self.imageBoxView.backgroundColor = [self redColor];
        self.iconImgView.lim_size = CGSizeMake(32.0f, 32.0f);
      
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.iconImgView.lim_size = CGSizeMake(32.0f, 32.0f);
    if(self.changeToSmall) {
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = self.lim_height/2.0f;
        self.imageBoxView.layer.masksToBounds = YES;
        self.imageBoxView.layer.cornerRadius = self.imageBoxView.lim_height/2.0f;
        self.iconImgView.lim_centerY_parent = self;
        self.iconImgView.lim_centerX_parent = self;
        
    }else{
        self.imageBoxView.lim_size = self.iconImgView.lim_size;
        if(self.style2) {
            self.lim_size = CGSizeMake(140.0f, 60.0f);
            self.layer.masksToBounds = YES;
            self.layer.cornerRadius = self.lim_height/2.0f;
            
            self.titleLbl.lim_centerY_parent = self;
            
            self.iconImgView.lim_centerY_parent = self;
            self.iconImgView.lim_left = 10.0f;
            
            CGFloat titleLeftSpace = 10.0f;
            
            CGFloat contentWidth = self.iconImgView.lim_width + titleLeftSpace + self.titleLbl.lim_width;
            self.iconImgView.lim_left = self.lim_width/2.0f - contentWidth/2.0f;
            self.titleLbl.lim_left = self.iconImgView.lim_right + titleLeftSpace;
            
        }else{
            self.lim_size = self.oldFrame.size;
            self.layer.masksToBounds = YES;
            self.layer.cornerRadius = 0.0f;
            
            self.imageBoxView.lim_size = CGSizeMake(self.lim_width, self.lim_width);
            self.imageBoxView.lim_centerX_parent = self;
            self.iconImgView.lim_centerX_parent = self.imageBoxView;
            self.iconImgView.lim_centerY_parent = self.imageBoxView;
            
            self.titleLbl.lim_top = self.imageBoxView.lim_bottom + 10.0f;
            self.titleLbl.lim_centerX_parent = self;
        }
    }
   
}

- (void)setStyle2:(BOOL)style2 {
    _style2 = style2;
    [self.iconImgView removeFromSuperview];
    if(_style2) {
        self.lim_size = CGSizeMake(140.0f, 60.0f);
        self.imageBoxView.hidden = YES;
        [self addSubview:self.iconImgView];
       
        self.backgroundColor =  [self redColor];
       
    }else{
        self.lim_size = self.oldFrame.size;
        self.imageBoxView.lim_size = self.iconImgView.lim_size;
        self.imageBoxView.hidden = NO;
        [self.imageBoxView addSubview:self.iconImgView];
        
        self.backgroundColor =  [UIColor clearColor];
        
    }
}


- (UIView *)imageBoxView {
    if(!_imageBoxView) {
        _imageBoxView = [[UIView alloc] initWithFrame:self.iconImgView.bounds];
        _imageBoxView.layer.masksToBounds = YES;
        _imageBoxView.layer.cornerRadius = _imageBoxView.lim_height/2.0f;
    }
    return _imageBoxView;
}


-(UIColor*) redColor {
    return  [UIColor colorWithRed:222.0f/255.0f green:113.0f/255.0f blue:100.0f/255.0f alpha:1.0f];
}

@end
