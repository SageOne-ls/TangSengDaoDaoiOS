//
//  WKRTCRoomInfo.h
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import <Foundation/Foundation.h>
#import "WKRTCStream.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKRTCConferenceInfo : NSObject

@property(nonatomic,copy) NSString *conferenceID;

@property(nonatomic, strong) NSArray<WKRTCStream*>* remoteStreams;

@end

NS_ASSUME_NONNULL_END
