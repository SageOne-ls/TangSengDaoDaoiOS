//
//  WKRTCStream.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKRTCStream : NSObject

@property(nonatomic,strong,nullable) id stream;

@property(nonatomic,assign) BOOL openVideo; // 是否开启视频

@property(nonatomic,assign) BOOL handsFree; // 免提

@property(nonatomic,assign) BOOL mute; // 静音

@property(nonatomic,copy) NSString *uid;

-(instancetype) initStream:(id)stream uid:(NSString*)uid;

- (void)attach:(NSObject*)renderer;
-(void) unattach ;

-(void) stop;

// 切换相机
-(void) switchCamera;


@end

NS_ASSUME_NONNULL_END
