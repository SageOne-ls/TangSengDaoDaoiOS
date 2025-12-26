//
//  WKParticipant.m
//  WuKongRTC
//
//  Created by tt on 2022/9/14.
//

#import "WKRTCParticipant.h"

@implementation WKRTCParticipant

-(instancetype) initWithUID:(NSString*)uid {
    self = [super init];
    if(self) {
        self.uid = uid;
    }
    return self;
}

@end
