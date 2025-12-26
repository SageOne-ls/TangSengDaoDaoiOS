//
//  WKRTCRoomUtil.m
//  WuKongRTC
//
//  Created by tt on 2022/9/17.
//

#import "WKRTCRoomUtil.h"

@implementation WKRTCRoomUtil


// 生成个人房间ID
+(NSString*) genPersonRoomID:(NSString*)uid toUID:(NSString*)toUID{
   
    if([toUID isEqualToString:uid]) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@@%@",uid,toUID];
}

// 从个人房间获取对方的uid
+(NSString*) getToFromRoomID:(NSString*)roomID {
    if([self isPersonRoom:roomID]) {
       NSArray<NSString*> *uids = [roomID componentsSeparatedByString:@"@"];
        if(uids.count == 2) {
            return uids[1];
        }
    }
    return nil;
}
// 是否是个人房间
+(BOOL) isPersonRoom:(NSString*)roomID {
    if(!roomID) {
        return false;
    }
    return [roomID containsString:@"@"];
}

+(NSArray<NSString*>*) getParticipantFromRoom:(NSString*)roomID {
    if([self isPersonRoom:roomID]) {
        return  [roomID componentsSeparatedByString:@"@"];
    }
    return nil;
}

@end
