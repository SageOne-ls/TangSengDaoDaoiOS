//
//  WKRTCClientManager.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCClientManager.h"
#import "WKRTCManager.h"
@interface WKRTCClientManager ()

@end

@implementation WKRTCClientManager

static WKRTCClientManager *_instance;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCClientManager *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

-(id<WKRTCClientProtocol>) getClient:(WKRTCMode)mode {
  
    id<WKRTCClientProtocol> clientProtocol = [WKRTCManager.shared.options.provider getClient:mode];
    clientProtocol.delegate = self.delegate;
    return clientProtocol;
}

@end
