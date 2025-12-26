//
//  WKPanelCallFuncItem.m
//  LiMaoSmallVideo
//
//  Created by tt on 2022/5/4.
//

#import "WKPanelCallFuncItem.h"
#import "WKRTCModule.h"
#import "WKRTCManager.h"
@implementation WKPanelCallFuncItem

- (NSString *)sid {
    return @"apm.wukong.call";
}

- (UIImage *)itemIcon {
    return [self imageName:@"func_video_normal"];
}

- (void)onPressed:(UIButton *)btn {
    id<WKConversationContext> context = self.inputPanel.conversationContext;
    
    if(context.channel.channelType == WK_GROUP) {
        [WKRTCManager.shared call:context.channel callType:WKRTCCallTypeAudio];
        return;
    }
    WKActionSheetView2 *sheet = [WKActionSheetView2 initWithTip:nil];
    [sheet addItem:[WKActionSheetButtonItem2 initWithTitle:LLang(@"视频聊天") onClick:^{
        [WKRTCManager.shared call:context.channel callType:WKRTCCallTypeVideo];
    }]];
    [sheet addItem:[WKActionSheetButtonItem2 initWithTitle:LLang(@"语音聊天") onClick:^{
        [WKRTCManager.shared call:context.channel callType:WKRTCCallTypeAudio];
    }]];
    [sheet setOnHide:^{
        btn.selected = false;
    }];
    [sheet show];
}

- (NSString *)title {
    return LLang(@"视频通话");
}

-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:[WKRTCModule globalID]];
}

@end
