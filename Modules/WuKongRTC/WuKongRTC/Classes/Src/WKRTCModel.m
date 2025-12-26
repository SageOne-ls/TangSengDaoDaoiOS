//
//  WKRTCModel.m
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import "WKRTCModel.h"
#import <WuKongBase/WuKongBase.h>
@implementation WKCreateRoomReq

@end
@implementation WKCreateRoomResp

+ (WKModel *)fromMap:(NSDictionary *)dictory type:(ModelMapType)type {
    WKCreateRoomResp *resp = [WKCreateRoomResp new];
    resp.roomID = dictory[@"room_id"]?:@"";
//    resp.token = dictory[@"token"]?:@"";
    return resp;
}

@end
