//
//  WKRTCOption.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCOption.h"
#import <WuKongBase/WuKongBase.h>
@implementation WKRTCOption

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.joinRoomTimeout = 32.0f;
        self.defaultAvatar = WKApp.shared.config.defaultAvatar;
        self.videoOtherUIHideInterval = 10.0f;
        self.p2pCallTimeout = 60.0f;
    }
    return self;
}

@end
