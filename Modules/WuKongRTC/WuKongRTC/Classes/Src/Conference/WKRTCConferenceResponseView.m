//
//  WKRTCConferenceResponseView.m
//  WuKongRTC
//
//  Created by tt on 2022/9/15.
//

#import "WKRTCConferenceResponseView.h"
#import "WKRTCManager.h"

#define numOfRow 4 // 每行显示参与人数量
#define avatarSpace 5.0f // 参与人头像间距

#define avatarSize 32.0f // 参与人头像大小

@interface WKRTCConferenceResponseView ()

@property(nonatomic,strong) NSString *callerUID; //呼叫人的uid
@property(nonatomic,strong) UIImageView *callerAvatarImgView; // 呼叫人的头像
@property(nonatomic,strong) UILabel *callerNameLbl; // 呼叫人的名称

@property(nonatomic,strong) UILabel *callTipLbl; // 呼叫提示语
@property(nonatomic,strong) UILabel *participantTipLbl; // 参与人提示
@property(nonatomic,strong) UIView *participantBox; // 参与人box

@property(nonatomic,strong) UIButton *hangupBtn; // 挂断
@property(nonatomic,strong) UIButton *answerBtn; // 接听

@end

@implementation WKRTCConferenceResponseView

- (instancetype)init
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        [self setup];
    }
    return self;
}


-(void) setup {
    [self setBackgroundColor:[UIColor blackColor]];
    
    [self addSubview:self.callerAvatarImgView];
//    [WKRTCClient shared].options.setUserAvatar(self.caller, self.callerAvatarImgView);
    
    [self addSubview:self.callerNameLbl];
    [self addSubview:self.callTipLbl];
    [self addSubview:self.participantTipLbl];
    [self addSubview:self.participantBox];
    [self addSubview:self.hangupBtn];
    [self addSubview:self.answerBtn];
    
    [self performSelector:@selector(autoHangup) withObject:nil afterDelay:WKRTCManager.shared.options.joinRoomTimeout - 2];
}

- (void)setParticipants:(NSArray<WKRTCParticipant *> *)participants {
    _participants = participants;
    __weak typeof(self) weakSelf = self;
    BOOL hasSelf = false;
    for (WKRTCParticipant *participant in participants) {
        if([participant.uid isEqualToString:WKRTCManager.shared.options.uid]) {
            hasSelf = true;
        }
        if(participant.role == WKRTCParticipantRoleInviter) {
            weakSelf.callerNameLbl.text = participant.name;
            [weakSelf.callerAvatarImgView lim_setImageWithURL:participant.avatar placeholderImage:WKRTCManager.shared.options.defaultAvatar];
            [weakSelf.callerNameLbl sizeToFit];
        }else{
            [weakSelf.participantBox addSubview:[weakSelf createParticipantAvatar:participant.avatar]];
        }
        
    }
    self.participantTipLbl.text =  [NSString stringWithFormat:LLang(@"还有%i人参与聊天"),participants.count - (hasSelf?1:2)];
    [self.participantTipLbl sizeToFit];
}

-(UIImageView*) createParticipantAvatar:(NSURL*)avatar {
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, avatarSize, avatarSize)];
    [imgView lim_setImageWithURL:avatar placeholderImage:WKRTCManager.shared.options.defaultAvatar];
    imgView.layer.masksToBounds = YES;
    imgView.layer.cornerRadius = 2.0f;
    return imgView;
}

-(void) autoHangup {
    [self hangupPressed];
}
-(CGFloat) topOffset {
    CGFloat safeTop = 0.0f;
    safeTop = [[UIApplication sharedApplication].keyWindow safeAreaInsets].top;
    CGFloat statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    return safeTop + statusHeight;
}

-(void) layoutSubviews {
    
    self.callerAvatarImgView.lim_width = 80.0f;
    self.callerAvatarImgView.lim_height = 80.0f;
    self.callerAvatarImgView.lim_top = [self topOffset] + 100.0f;
    self.callerAvatarImgView.lim_centerX_parent = self;
    
    self.callerNameLbl.lim_top = self.callerAvatarImgView.lim_bottom + 20.0f;
    self.callerNameLbl.lim_centerX_parent  =self;
    
    self.callTipLbl.lim_top = self.callerNameLbl.lim_bottom + 20.0f;
    self.callTipLbl.lim_centerX_parent = self;
    
    self.participantTipLbl.lim_top = self.callTipLbl.lim_bottom + 40.0f;
    self.participantTipLbl.lim_centerX_parent = self;
    
    NSInteger rowNum = self.participantBox.subviews.count/numOfRow;
    if(self.participantBox.subviews.count%numOfRow != 0) {
        rowNum++;
    }
    CGFloat boxHeight = avatarSize * rowNum + (rowNum-1)*avatarSpace;
    CGFloat boxWidth = avatarSize * numOfRow + (numOfRow-1)*avatarSpace;
    self.participantBox.lim_width = boxWidth;
    self.participantBox.lim_height = boxHeight;
    self.participantBox.lim_centerX_parent = self;
    self.participantBox.lim_top = self.participantTipLbl.lim_bottom + 20.0f;
    
    NSInteger currRow = 0;
    NSInteger currCol = 0;
    for (NSInteger i=0; i<self.participantBox.subviews.count; i++) {
        if(i%numOfRow == 0) {
            currRow++;
            currCol = 0;
        }
        currCol++;
        
        UIView *avatarView =self.participantBox.subviews[i];
        avatarView.lim_left = (avatarSize+avatarSpace) * (currCol-1);
        avatarView.lim_top = (avatarSize+avatarSpace) * (currRow-1);
        
    }
    // 最后一行居中显示
    if(self.participantBox.subviews.count%numOfRow != 0) {
        UIView *lastView = [self.participantBox.subviews lastObject];
        CGFloat leftOffset =  self.participantBox.lim_width/2.0f - lastView.lim_right/2.0f;
        for (NSInteger i=self.participantBox.subviews.count%numOfRow; i>0; i--) {
           UIView *view =   self.participantBox.subviews[self.participantBox.subviews.count - i];
            view.lim_left += leftOffset;
        }
    }
    CGFloat safeBottom = 0.0f;
    safeBottom = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    
    self.hangupBtn.lim_top = self.lim_height - safeBottom - 50.0f - self.hangupBtn.lim_height;
    self.hangupBtn.lim_left = 80.0f;
    
    self.answerBtn.lim_top = self.hangupBtn.lim_top;
    self.answerBtn.lim_left = self.lim_width - self.hangupBtn.lim_left - self.answerBtn.lim_width;
   
}

- (UIImageView *)callerAvatarImgView  {
    if(!_callerAvatarImgView) {
        _callerAvatarImgView = [[UIImageView alloc] init];
        _callerAvatarImgView.layer.masksToBounds = YES;
        _callerAvatarImgView.layer.cornerRadius = 8.0f;
    }
    return _callerAvatarImgView;
}

- (UILabel *)callerNameLbl {
    if(!_callerNameLbl) {
        _callerNameLbl = [[UILabel alloc] init];
        _callerNameLbl.text = @"--";
        _callerNameLbl.font = [[WKApp shared].config appFontOfSize:20.0f];
        _callerNameLbl.textColor = [UIColor whiteColor];
        [_callerNameLbl sizeToFit];
    }
    return _callerNameLbl;
}

- (UILabel *)callTipLbl {
    if(!_callTipLbl) {
        _callTipLbl = [[UILabel alloc] init];
        _callTipLbl.text = LLang(@"邀请你加入语音聊天...");
        _callTipLbl.font = [[WKApp shared].config appFontOfSize:16.0f];
        _callTipLbl.textColor = [UIColor grayColor];
        [_callTipLbl sizeToFit];
    }
    return _callTipLbl;
}

- (UILabel *)participantTipLbl {
    if(!_participantTipLbl) {
        _participantTipLbl = [[UILabel alloc] init];
        _participantTipLbl.font = [[WKApp shared].config appFontOfSize:14.0f];
        _participantTipLbl.textColor = [UIColor grayColor];
    }
    return _participantTipLbl;
}

- (UIView *)participantBox {
    if(!_participantBox) {
        _participantBox = [[UIView alloc] init];
    }
    return _participantBox;
}

- (UIButton *)hangupBtn {
    if(!_hangupBtn) {
        _hangupBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 60.0f)];
        _hangupBtn.layer.masksToBounds = YES;
        _hangupBtn.layer.cornerRadius = _hangupBtn.lim_height/2.0f;
        [_hangupBtn setBackgroundColor:[UIColor colorWithRed:201.0f/255.0f green:83.0f/255.0f blue:79.0f/255.0f alpha:1.0f]];
        [_hangupBtn setImage:[self imageName:@"hangup"] forState:UIControlStateNormal];
        [_hangupBtn addTarget:self action:@selector(hangupPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _hangupBtn;
}

- (UIButton *)answerBtn {
    if(!_answerBtn) {
        _answerBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 60.0f)];
        _answerBtn.layer.masksToBounds = YES;
        _answerBtn.layer.cornerRadius = _answerBtn.lim_height/2.0f;
        [_answerBtn setBackgroundColor:[UIColor colorWithRed:85.0f/255.0f green:183.0f/255.0f blue:55.0f/255.0f alpha:1.0f]];
        [_answerBtn setImage:[self imageName:@"answer"] forState:UIControlStateNormal];
        [_answerBtn addTarget:self action:@selector(answerPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    return _answerBtn;
}

-(void) hangupPressed {
   // [self dismissViewControllerAnimated:YES completion:nil];
//    if([WKRTCClient shared].options.receiveCallback) {
//        [WKRTCClient shared].options.receiveCallback(self.roomID,WKRTCReceiveStatusHangup);
//    }
    if(self.onHangup) {
        self.onHangup();
    }
}

-(void) answerPressed {
//    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHangup) object:nil];
//    [self dismissViewControllerAnimated:NO completion:nil];
//
//    if([WKRTCClient shared].options.receiveCallback) {
//        [WKRTCClient shared].options.receiveCallback(self.roomID,WKRTCReceiveStatusAnswer);
//    }
    if(self.onAnswer) {
        self.onAnswer();
    }
    
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:@"WuKongRTC"];
}




@end
