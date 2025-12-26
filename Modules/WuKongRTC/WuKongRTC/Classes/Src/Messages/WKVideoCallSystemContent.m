//
//  WKVideoCallSystemContent.m
//  LiMaoQCRTC
//
//  Created by tt on 2020/9/27.
//

#import "WKVideoCallSystemContent.h"

@implementation WKVideoCallSystemContent

+(WKVideoCallSystemContent*) initWithContent:(NSString*)content second:(NSNumber*)second type:(NSInteger)type{
    WKVideoCallSystemContent *model = [WKVideoCallSystemContent new];
    model.content = content;
    model.second = second;
    model.type = type;
    return model;
}

- (void)decodeWithJSON:(NSDictionary *)contentDic {
    self.content = contentDic[@"content"]?:@"";
    self.second = contentDic[@"second"];
    if(contentDic[@"call_type"]) {
        self.callType = [contentDic[@"call_type"] integerValue];
    }
    if(contentDic[@"result_type"]) {
        self.resultType = [contentDic[@"result_type"] integerValue];
    }
    if(contentDic[@"status"]) {
        self.agree = [contentDic[@"status"] boolValue];
    }
    
    if(self.second && self.second.integerValue>0) {
        self.content = [NSString stringWithFormat:@"通话时长 %@",[self formatSecond:self.second]];
    }
}

- (NSDictionary *)encodeWithJSON {
    if(self.second && self.second.integerValue>0) {
        self.content = [NSString stringWithFormat:@"通话时长 %@",[self formatSecond:self.second]];
    }
    NSInteger status = self.agree?1:0;
    
   
    return @{@"content":self.content?:@"",@"second":self.second?:@(0),@"call_type":@(self.callType),@"status":@(status),@"result_type":@(self.resultType)};
}

- (NSInteger)realContentType {
    if(_type == 0) {
        return [super realContentType];
    }
    return _type;
}


-(NSString*) formatSecond:(NSNumber*)time {
    NSInteger second = time.integerValue%60;
    NSInteger min = time.integerValue/60;
    
    NSString *secondStr = [NSString stringWithFormat:@"%li",second];
    if(second<10) {
        secondStr = [NSString stringWithFormat:@"0%li",second];
    }
    NSString *minStr = [NSString stringWithFormat:@"%li",min];
    if(min<10) {
        minStr = [NSString stringWithFormat:@"0%li",min];
    }
    return [NSString stringWithFormat:@"%@:%@",minStr,secondStr];
}



- (NSString *)conversationDigest {
    if(self.callType == WKRTCCallTypeAudio) {
        return @"[语音通话]";
    }
    return @"[视频通话]";
}

- (NSString *)searchableWord {
    if(self.callType == WKRTCCallTypeAudio) {
        return @"[语音通话]";
    }
    return @"[视频通话]";
}
@end
