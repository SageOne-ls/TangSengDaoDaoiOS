//
//  WKVideoCallSystemContent.h
//  LiMaoQCRTC
//
//  Created by tt on 2020/9/27.
//

#import <WuKongBase/WuKongBase.h>
#import "WKRTCConstants.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKVideoCallSystemContent : WKMessageContent

+(WKVideoCallSystemContent*) initWithContent:(NSString*)content second:(NSNumber*)second type:(NSInteger)type;

@property(nonatomic,assign) NSInteger type;
@property(nonatomic,copy) NSString *content; // 通话描述文本
@property(nonatomic,assign) NSNumber *second; // 通话秒数(只有接通后才有值)
@property(nonatomic,assign) WKRTCCallType callType; // 呼叫类型
@property(nonatomic,assign) NSInteger resultType; // 通话结果
@property(nonatomic,assign) BOOL agree; // 是否同意


@end

NS_ASSUME_NONNULL_END
