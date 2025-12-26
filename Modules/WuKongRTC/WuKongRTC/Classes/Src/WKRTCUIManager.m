//
//  WKRTCUIManager.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCUIManager.h"
#import "WKP2PChatView.h"
#import "WKRTCConferenceView.h"
@implementation WKRTCUIManager


static WKRTCUIManager *_instance;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCUIManager *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

-(id<WKRTCChatViewProtocol>) createChatView:(NSArray<WKRTCParticipant*>*)participants mode:(WKRTCMode)mode viewType:(WKRTCViewType)viewType callType:(WKRTCCallType)type{
    if(mode == WKRTCModeP2P) {
        return [WKP2PChatView participants:participants viewType:viewType callType:type];
    }
    return [WKRTCConferenceView participants:participants viewType:viewType];
}


@end
