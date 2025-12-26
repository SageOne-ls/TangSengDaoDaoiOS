//
//  WKRTCProviderProtocol.h
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import <Foundation/Foundation.h>
#import "WKRTCClientProtocol.h"
#import "WKRTCConstants.h"
#import "WKRTCStream.h"
NS_ASSUME_NONNULL_BEGIN

@protocol WKRTCProviderProtocol <NSObject>


-(id<WKRTCClientProtocol>) getClient:(WKRTCMode)mode;

-(WKRTCStream*) getLocalStream;

-(void) streamRender:(id)stream target:(id)target;

-(void) streamUnrender:(id)stream target:(id)target;

-(void) switchCamera;

-(BOOL) isOpenVideo:(id)stream;

-(void) openVideo:(BOOL)openVideo stream:(id)stream;

- (void)openVoice:(BOOL)on stream:(id)stream;



@end

NS_ASSUME_NONNULL_END
