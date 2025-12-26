//
//  WKAudioSessionManager.h
//  WuKongRTC
//
//  Created by tt on 2022/9/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class WKAudioSessionManager;
NS_ASSUME_NONNULL_BEGIN

@protocol WKAudioSessionManagerDelegate <NSObject>

@optional

-(void) audioSessionManagerDidRouteChange:(WKAudioSessionManager*)manager;

@end

@interface WKAudioSessionManager : NSObject


+ (WKAudioSessionManager *)shared;

@property(nonatomic,assign) BOOL isSpeaker; // 是否打开扬声器

@property (nonatomic, strong) NSMutableArray<AVAudioSessionPortDescription *> *availablePorts;

@property(nonatomic,strong,nullable) AVAudioSessionPortDescription *suggetAudioSessionPortDescription;
@property(nonatomic,assign) AVAudioSessionPortOverride suggetAudioSessionPortOverride;
/**
 添加委托
 
 @param delegate <#delegate description#>
 */
-(void) addDelegate:(id<WKAudioSessionManagerDelegate>) delegate;


/**
 移除委托
 
 @param delegate <#delegate description#>
 */
-(void)removeDelegate:(id<WKAudioSessionManagerDelegate>) delegate;

@end

NS_ASSUME_NONNULL_END
