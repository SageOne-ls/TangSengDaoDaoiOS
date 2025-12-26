//
//  WKRTCVoicePlayUtil.h
//  WuKongRTC
//
//  Created by tt on 2021/5/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRTCVoicePlayUtil : NSObject

+ (WKRTCVoicePlayUtil *)shared;

/**
  呼叫
 */
-(void) call;

/**
 接听
 */
-(void) receive;

/**
  震动
 */
- (void)shock;

/**
 挂断
 */
-(void) hangup;


-(void) stopAll;

@end

NS_ASSUME_NONNULL_END
