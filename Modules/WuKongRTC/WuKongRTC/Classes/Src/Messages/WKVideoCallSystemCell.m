//
//  WKVideoCallSystemCell.m
//  LiMaoQCRTC
//
//  Created by tt on 2020/9/27.
//

#import "WKVideoCallSystemCell.h"
#import "WKVideoCallSystemContent.h"
#import "WKRTCModule.h"
#import "WKRTCManager.h"
@interface WKVideoCallSystemCell ()

@property(nonatomic,strong) UILabel *contentLbl;

@property(nonatomic,strong) UIImageView *iconImgView;

@end

@implementation WKVideoCallSystemCell

#define iconSize CGSizeMake(24.0f,24.0f) // icon大小

#define iconToContentSpace 5.0f // icon到内容的距离

+ (CGSize)contentSizeForMessage:(WKMessageModel *)model {
    WKVideoCallSystemContent *content = (WKVideoCallSystemContent*)model.content;
   CGSize contentSize=  [self getTextSize:content.content maxWidth:[WKApp shared].config.messageContentMaxWidth];
    
    CGSize trailingSize = [WKTrailingView size:model];
    return CGSizeMake(iconToContentSpace + iconSize.width + contentSize.width + trailingSize.width, 30.0f);
}

- (void)initUI {
    [super initUI];
    [self.messageContentView addSubview:self.iconImgView];
    [self.messageContentView addSubview:self.contentLbl];
}


- (void)refresh:(WKMessageModel *)model {
    [super refresh:model];
    WKVideoCallSystemContent *content = (WKVideoCallSystemContent*)model.content;
    self.contentLbl.text = content.content;
    if(model.isSend) {
        self.contentLbl.textColor = [WKApp shared].config.messageSendTextColor;
    }else{
        self.contentLbl.textColor = [WKApp shared].config.messageRecvTextColor;
    }
   
    self.iconImgView.image = [self imageName:[self getIconName:content.callType]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.iconImgView.lim_top = self.messageContentView.lim_height/2.0f - self.iconImgView.lim_height/2.0f;
    
    [self.contentLbl sizeToFit];
    self.contentLbl.lim_top = self.messageContentView.lim_height/2.0f - self.contentLbl.lim_height/2.0f;
    
    self.contentLbl.lim_left =  0;
    self.iconImgView.lim_left = self.contentLbl.lim_right + iconToContentSpace;
}

- (void)onTap {
    if (self.messageModel.channelInfo.status == WKChannelStatusBlacklist) {//黑名单中
        [[WKNavigationManager shared].topViewController.view showHUDWithHide:LLang(@"已把对方拉入黑名单，暂不可拨打音视频")];
        return;
    }
    
    WKChannel *channel = self.messageModel.channel;
    WKActionSheetView2 *sheet = [WKActionSheetView2 initWithTip:nil];
    [sheet addItem:[WKActionSheetButtonItem2 initWithTitle:@"视频聊天" onClick:^{
        [[WKRTCManager shared] call:channel callType:WKRTCCallTypeVideo];
        //[WKRTCManager.shared call:self.messageModel.channel type:WKCallTypeVideo];
    }]];
    [sheet addItem:[WKActionSheetButtonItem2 initWithTitle:@"语音聊天" onClick:^{
        [[WKRTCManager shared] call:channel callType:WKRTCCallTypeAudio];
//        [WKRTCManager.shared call:self.messageModel.channel type:WKCallTypeAudio];
    }]];
    [sheet show];
}

+ (CGSize) getTextSize:(NSString*) text maxWidth:(CGFloat)maxWidth{
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
   NSAttributedString *string = [[NSAttributedString alloc]initWithString:text attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[WKApp shared].config.messageTextFontSize], NSParagraphStyleAttributeName:style}];
    CGSize size =  [string boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil].size;
    return size;
}

//// 气泡边距
//+(UIEdgeInsets) bubbleEdgeInsets {
//    return WK_BUBBLE_INSETS;
//}


-(NSString*) getIconName:(WKCallType)callType {
    switch (callType) {
        case WKCallTypeAudio:
            return @"icon_voice_chat";
        default:
            if(self.messageModel.isSend) {
                return @"icon_send_video_chat";
            }
            return @"icon_received_video_chat";
    }
}

- (UILabel *)contentLbl {
    if(!_contentLbl) {
        _contentLbl = [[UILabel alloc] init];
        _contentLbl.font = [[WKApp shared].config appFontOfSize:[WKApp shared].config.messageTextFontSize];
    }
    return _contentLbl;
}

- (UIImageView *)iconImgView {
    if(!_iconImgView) {
        _iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, iconSize.width, iconSize.height)];
    }
    return _iconImgView;
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:[WKRTCModule globalID]];
}

@end
