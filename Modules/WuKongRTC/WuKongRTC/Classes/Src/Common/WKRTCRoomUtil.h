//
//  WKRTCRoomUtil.h
//  WuKongRTC
//
//  Created by tt on 2022/9/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRTCRoomUtil : NSObject

+(NSString*) genPersonRoomID:(NSString*)uid toUID:(NSString*)toUID;

+(NSString*) getToFromRoomID:(NSString*)roomID;

+(BOOL) isPersonRoom:(NSString*)roomID;

+(NSArray<NSString*>*) getParticipantFromRoom:(NSString*)roomID;

@end

NS_ASSUME_NONNULL_END
