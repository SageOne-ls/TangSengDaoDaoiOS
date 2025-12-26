//
//  WKRTCConferenceClientProtocol.h
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import <Foundation/Foundation.h>
#import "WKRTCConferenceInfo.h"
NS_ASSUME_NONNULL_BEGIN



@protocol WKRTCConferenceClientProtocol <NSObject>

-(void) createConference:(NSArray<NSString*>*)participants complete:(void(^)(NSString *roomID,NSString *token,NSError *error))complete;

- (void)subscribe:(NSString*)token
            complete:(nonnull void (^)(NSError * _Nullable))complete;

-(void) leaveConference:(void(^)(NSError * __nullable error))complete;


@end

NS_ASSUME_NONNULL_END
