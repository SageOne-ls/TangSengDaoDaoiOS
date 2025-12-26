//
//  WKRTCDataContent.m
//  WuKongRTC
//
//  Created by tt on 2021/5/10.
//

#import "WKRTCDataContent.h"
#import <WuKongBase/WKConstant.h>
@interface WKRTCDataContent ()



@end

@implementation WKRTCDataContent




+(WKRTCDataContent*) data:(NSString*)data {
    WKRTCDataContent *content = [WKRTCDataContent new];
    content.data = data;
    return content;
}


- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.data = contentDic[@"content"]?:@"";

}

- (NSDictionary *)encodeWithJSON {
    return @{@"content":self.data?:@""};
}

+(NSNumber*) contentType {
    return @(WK_VIDEOCALL_DATA);
}
@end
