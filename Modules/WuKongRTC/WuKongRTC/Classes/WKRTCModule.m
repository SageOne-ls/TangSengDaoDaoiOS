//
//  WKRTCModule.m
//  WuKongRTC
//
//  Created by tt on 2021/4/30.
//

#import "WKRTCModule.h"
#import "WKRTCDataContent.h"
#import "WKVideoCallSystemCell.h"
#import "WKVideoCallSystemContent.h"
#import "WKRTCManager.h"
#import "WKRTCOWTProvider.h"
#import <WuKongIMSDK/WuKongIMSDK.h>
#import <UserNotifications/UserNotifications.h>
#import "WKRTCVoicePlayUtil.h"
#import "WKPanelCallFuncItem.h"
@WKModule(WKRTCModule)

@interface WKRTCModule ()<WKCMDManagerDelegate,WKChatManagerDelegate,WKRTCManagerDelegate,WKAppDelegate,UNUserNotificationCenterDelegate>

@end

@implementation WKRTCModule

+ (NSString *)globalID {
    return @"WuKongRTC";
}

- (NSString *) moduleId {
    return [WKRTCModule globalID];
}

- (void)moduleInit:(WKModuleContext *)context {
    WKLogDebug(@"【WuKongRTC】模块初始化！");
    
    // call
        [self setMethod:WKPOINT_CATEGORY_PANELFUNCITEM_CALL handler:^id _Nullable(id  _Nonnull param) {
            id<WKConversationContext> context = param[@"context"];
            NSString *channelID = context.channel.channelId;
            if(context.channel.channelType == WK_PERSON) {
                if([channelID isEqualToString:[WKApp shared].config.fileHelperUID]) {
                    return nil;
                }
                if([channelID isEqualToString:[WKApp shared].config.systemUID]) {
                    return nil;
                }
            }
            WKPanelDefaultFuncItem *item = [[WKPanelCallFuncItem alloc] init];
            item.sort = 6000;
            return item;
        } category:WKPOINT_CATEGORY_PANELFUNCITEM];

    [[WKApp shared] registerCellClass:WKVideoCallSystemCell.class contentType:WK_VIDEOCALL_RESULT]; //  取消通话
    

   
    // 注册视频通话的消息content
    [[WKSDK shared] registerMessageContent: WKVideoCallSystemContent.class contentType:WK_VIDEOCALL_RESULT]; //  取消通话
    [[WKSDK shared] registerMessageContent:WKVideoCallSystemContent.class contentType:WK_VIDEOCALL_SWITCH_TO_VIDEO]; // 切换视频
    [[WKSDK shared] registerMessageContent:WKVideoCallSystemContent.class contentType:WK_VIDEOCALL_SWITCH_TO_VIDEO_REPLY]; // 切换视频
    
    [[WKSDK shared] registerMessageContent: WKRTCDataContent.class contentType:WK_VIDEOCALL_DATA]; //  RTC数据传输
    
    [WKRTCManager.shared setDelegate:self];
    
    [WKRTCManager.shared.options setGetParticipant:^(NSString * _Nonnull uid, void (^ _Nonnull callback)(WKRTCParticipant * _Nonnull)) {
        WKRTCParticipant *participant = [WKRTCParticipant new];
        WKChannelInfo *channelInfo = [WKSDK.shared.channelManager getChannelInfo:[WKChannel personWithChannelID:uid]];
        participant.uid = uid;
        if(channelInfo) {
            participant.name = channelInfo.displayName;
            participant.avatar = [NSURL URLWithString:[WKAvatarUtil getAvatar:uid]];
            callback(participant);
            return;
        }
        [WKSDK.shared.channelManager fetchChannelInfo:[WKChannel personWithChannelID:uid] completion:^(WKChannelInfo * channelInfo) {
            participant.name = channelInfo.displayName;
            participant.avatar = [NSURL URLWithString:[WKAvatarUtil getAvatar:uid]];
            callback(participant);
        }];
       
    }];
    
    [WKApp.shared addDelegate:self];
   
    WKRTCManager.shared.options.provider =  [WKRTCOWTProvider new];
    

    // 更多面板 -> 视频通话
    __weak typeof(self) weakSelf = self;
   
   
    
    [self setMethod:WKPOINT_VIDEOCALL_SUPPORT_FNC handler:^id _Nullable(id  _Nonnull param) {
        BOOL moduleOn = [WKApp.shared.remoteConfig moduleOn:[weakSelf moduleId]];
        if(!moduleOn) {
            return nil;
        }
        WKChannel *channel = param[@"channel"];
         id<WKConversationContext> conversationContext = param[@"context"];
         if(channel.channelType == WK_CustomerService) {
             return nil;
         }
         if(channel.channelType == WK_PERSON) {
             if([channel.channelId isEqualToString:WKApp.shared.config.fileHelperUID] || [channel.channelId isEqualToString:WKApp.shared.config.systemUID]) {
                 return nil;
             }
         }
       
        
         return ^(WKChannel *channel,WKCallType callType){
             if(conversationContext && [conversationContext forbidden]) {
                 [[WKNavigationManager shared].topViewController.view showHUDWithHide:LLangW(@"禁言中",weakSelf)];
                 return;
             }
             if(callType == WKCallTypeAll) {
                 WKActionSheetView2 *sheet = [WKActionSheetView2 initWithTip:nil];
                 [sheet addItem:[WKActionSheetButtonItem2 initWithTitle:LLangW(@"视频聊天",weakSelf) onClick:^{
                     [[WKRTCManager shared] call:channel callType:WKRTCCallTypeVideo];
                 }]];
                 [sheet addItem:[WKActionSheetButtonItem2 initWithTitle:LLangW(@"语音聊天",weakSelf) onClick:^{
                     [[WKRTCManager shared] call:channel callType:WKRTCCallTypeAudio];
                 }]];
                 [sheet show];
             }else  {
                 [[WKRTCManager shared] call:channel callType:(WKRTCCallType)callType];
//                 
//                 if(channel.channelType == WK_GROUP) {
//                     [[WKRTCClient shared] call:channel callType:callType];
//                 }else{
//                     [[WKRTCManager shared] call:channel callType:(WKRTCCallType)callType];
//                 }
                
             }
            
         };
       }];
    
    [[WKSDK shared].cmdManager addDelegate:self];
    [[WKSDK shared].chatManager addDelegate:self];
}

- (BOOL)moduleDidFinishLaunching:(WKModuleContext *)context {
    if([WKApp.shared isLogined]) {
        WKRTCManager.shared.options.uid = WKApp.shared.loginInfo.uid;
    }
    return YES;
}

-(NSString*) makeSoundFile {
    //    [WKRTCVoicePlayUtil.shared shock]; // 震动
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
    //    NSString *soundsDir = [self getSoundsDirectory];
        
        NSString *soundsDir = [NSHomeDirectory() stringByAppendingString:@"/Library/Sounds/"];

        NSString *soundName = @"receive.caf";
        NSString *destSoundPath = [soundsDir stringByAppendingPathComponent:soundName];
        if(![fileManager fileExistsAtPath:destSoundPath]) {
            NSString *receiveFile =  [[self resourceBundle] pathForResource:[NSString stringWithFormat:@"Others/%@",soundName] ofType:@""];
    //        [fileManager copyItemAtPath:receiveFile toPath:destSoundPath error:nil];
            [WKFileUtil copyFileFromPath:receiveFile toPath:destSoundPath];
        }
    return soundName;
}

- (void)moduleDidReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSString *soundName = [self makeSoundFile];
   
    
    WKRTCCallType callType = WKRTCCallTypeAudio;
    if(userInfo[@"call_type"]) {
        callType = [userInfo[@"call_type"] integerValue];
    }
    NSString *fromUID = @"";
    if(userInfo[@"from_uid"]) {
        fromUID = userInfo[@"from_uid"];
    }
    NSString *voipIdentifier = @"voip";
    
   
    NSString *operation = userInfo[@"operation"]?:@"";
    if([operation isEqualToString:@"cancel"]) {
        WKChannel *currentCallingChannel = WKRTCManager.shared.currentChannel;
        if(!currentCallingChannel || currentCallingChannel.channelType != WK_PERSON) {
            return;
        }
        if(![fromUID isEqualToString:currentCallingChannel.channelId]) {
            return;
        }
        [self removeVoipNotification:voipIdentifier];
        return;
    }
    
    // 显示本地通知
    [self showVoipNotification:userInfo soundName:soundName identifier:voipIdentifier];
    
    // 唤醒IM 10秒超时
//    [WKSDK.shared.connectionManager wakeup:10 complete:^(NSError * _Nullable error) {
//        if(error) {
//            completionHandler(UIBackgroundFetchResultFailed);
//            return;
//        }
//        completionHandler(UIBackgroundFetchResultNewData);
//    }];
    
    completionHandler(UIBackgroundFetchResultNewData);
}

-(void) removeVoipNotification:(NSString*)voipIdentifier {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeDeliveredNotificationsWithIdentifiers:@[voipIdentifier]];
}

-(void) showVoipNotification:(NSDictionary*)dataDict soundName:(NSString*)soundName identifier:(NSString*)voipIdentifier{
    
    WKRTCCallType callType = WKRTCCallTypeAudio;
    if(dataDict[@"call_type"]) {
        callType = [dataDict[@"call_type"] integerValue];
    }
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.sound = [UNNotificationSound soundNamed:soundName];
            // 标题
    if(callType == WKRTCCallTypeVideo) {
        content.title = @"视频通话";
    }else {
        content.title = @"语音通话";
    }
    
            // 内容
    content.body = dataDict[@"content"]?:@"";
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:voipIdentifier content:content trigger:nil];
           
    [center addNotificationRequest:request withCompletionHandler:^(NSError *_Nullable error) {
        NSLog(@"成功添加推送");
    }];
    
}


-(UIImage*) imageName:(NSString*)name {
    return [[WKApp shared] loadImage:name moduleID:[self moduleId]];
}

#pragma mark -- WKCMDManagerDelegate

- (void)cmdManager:(WKCMDManager *)manager onCMD:(WKCMDModel *)model {
//    if([model.cmd isEqualToString:WKCMDRTCRoomInvoke]) {
//        NSString *caller = model.param[@"inviter"];
//        NSString *roomID = model.param[@"room_id"];
//        NSArray *participants = model.param[@"participants"];
//        [[WKRTCClient shared] receiveConferenceCall:roomID caller:caller participants:participants];
//
//    }else if([model.cmd isEqualToString:WKCMDRTCRoomHangup]) {
//        NSDictionary *param = model.param;
//        NSString *participant = param[@"participant"];
//        [[WKRTCClient shared] removeParticipant:participant reason:@"已拒绝"];
//    }
}

#pragma mark -- WKChatManagerDelegate

- (void)onRecvMessages:(WKMessage*)message left:(NSInteger)left {
//    if(message.contentType == WK_VIDEOCALL_RECEIVED) { // 收到通话
//        [[WKRTCClient shared] receiveCall:message.channel.channelId];
//    }else if(message.contentType == WK_VIDEOCALL_ACCEPT) { // 接受通话
//        [WKRTCClient shared].status = WKRTCStatusP2PAccepted; // 改变状态触发监听
//    }else if(message.contentType == WK_VIDEOCALL_HANGUP || message.contentType == WK_VIDEOCALL_REFUSE) {
//        [[WKRTCClient shared] endCall];
//    }
}

#pragma mark -- WKAppDelegate

- (void)appLoginSuccess {
    WKRTCManager.shared.options.uid = WKApp.shared.loginInfo.uid;
}

#pragma mark -- WKRTCManagerDelegate

- (void)rtcManager:(WKRTCManager *)manager didInviteAtChannel:(WKChannel *)channel data:(NSDictionary*)dataDict complete:(void (^)(NSArray<NSString *> * _Nonnull))complete {
    if(channel.channelType == WK_PERSON) {
        complete(@[channel.channelId]);
    }else if(channel.channelType == WK_GROUP) {
        WKMemberListVC *memberListVC = [[WKMemberListVC alloc] init];
        memberListVC.channel = channel;
        memberListVC.edit = true;
        __weak typeof(memberListVC) memberListVCWeak = memberListVC;
        NSMutableArray *hiddenUsers = [NSMutableArray arrayWithArray:@[WKApp.shared.loginInfo.uid,WKApp.shared.config.fileHelperUID,WKApp.shared.config.systemUID]];
        NSArray<NSString*> *participants = dataDict[@"participants"];
        if(participants) {
            [hiddenUsers addObjectsFromArray:participants];
        }
        memberListVC.hiddenUsers = hiddenUsers;
        [memberListVC setOnFinishedSelect:^(NSArray<NSString*>*uids){
            [memberListVCWeak dismissViewControllerAnimated:YES completion:nil];
            complete(uids);
            
        }];
        [manager presentViewController:memberListVC];
    }
    
}

@end
