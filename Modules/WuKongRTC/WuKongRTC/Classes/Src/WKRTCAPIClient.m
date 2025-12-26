//
//  WKRTCAPIClient.m
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import "WKRTCAPIClient.h"
#import "WKRTCRoomUtil.h"
@implementation WKRTCAPIClient


static WKRTCAPIClient *_instance;

+ (id)allocWithZone:(NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (WKRTCAPIClient *)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    return _instance;
}

- (void)createRoom:(WKCreateRoomReq *)req complete:(void(^)(WKCreateRoomResp *resp,NSError *error)) complete{
    [[WKAPIClient sharedClient] POST:@"rtc/rooms" parameters:@{
        @"name": req.name?:@"",
        @"uids": req.uids?:@[],
        @"channel_id": req.channelID?:@"",
        @"channel_type":@(req.channelType),
        
    } model:WKCreateRoomResp.class].then(^(WKCreateRoomResp *resp){
        if(complete) {
            complete(resp,nil);
        }
    }).catch(^(NSError *error){
        if(complete) {
            complete(nil,error);
        }
    });
}


- (void)getToken:(NSString *)roomID complete:(void(^)(NSString *token,NSError *error))complete{
    if([WKRTCRoomUtil isPersonRoom:roomID]) {
        complete(@"no need token",nil);
        return;
    }
    [[WKAPIClient sharedClient] GET:[NSString stringWithFormat:@"rtc/rooms/%@/token",roomID] parameters:@{}].then(^(NSDictionary *result){
        if(complete) {
            complete(result[@"token"],nil);
        }
    }).catch(^(NSError *error){
        if(complete) {
            complete(nil,error);
        }
    });
}

-(void) invoke:(NSString*)roomID uids:(NSArray<NSString*>*)uids complete:(void(^)(NSError * __nullable error))complete{
    [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/rooms/%@/invoke",roomID] parameters:@{@"uids":uids}].then(^{
        if(complete) {
            complete(nil);
        }
    }).catch(^(NSError *error){
        if(complete) {
            complete(error);
        }
    });
}

-(void) roomRefuse:(NSString*)roomID complete:(void(^)(NSError * __nullable error))complete{
    [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/rooms/%@/refuse",roomID] parameters:@{}].then(^(){
        if(complete) {
            complete(nil);
        }
    }).catch(^(NSError *error){
        if(complete) {
            complete(error);
        }
    });
}

-(void) roomJoined:(NSString*)roomID complete:(void(^)(NSError * __nullable error))complete {
    [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/rooms/%@/joined",roomID] parameters:@{}].then(^(){
        if(complete) {
            complete(nil);
        }
    }).catch(^(NSError *error){
        if(complete) {
            complete(error);
        }
    });
}

- (void)roomHangup:(NSString *)roomID complete:(void (^)(NSError * _Nullable))complete {
    [[WKAPIClient sharedClient] POST:[NSString stringWithFormat:@"rtc/rooms/%@/hangup",roomID] parameters:@{}].then(^(){
        if(complete) {
            complete(nil);
        }
    }).catch(^(NSError *error){
        if(complete) {
            complete(error);
        }
    });
}


@end
