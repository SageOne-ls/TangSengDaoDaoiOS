//
//  WKRTCDataContent.h
//  WuKongRTC
//
//  Created by tt on 2021/5/10.
//

#import <WuKongBase/WuKongBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRTCDataContent : WKMessageContent

@property(nonatomic,copy) NSString *data;

+(WKRTCDataContent*) data:(NSString*)data;

@end

NS_ASSUME_NONNULL_END
