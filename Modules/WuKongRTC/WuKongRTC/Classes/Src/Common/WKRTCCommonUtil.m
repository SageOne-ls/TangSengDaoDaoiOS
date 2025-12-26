//
//  WKRTCCommonUtil.m
//  WuKongRTC
//
//  Created by tt on 2021/5/7.
//

#import "WKRTCCommonUtil.h"
@implementation WKRTCCommonUtil

//无论全屏显示还是小屏显示，都需要充满，所以需要对size处理
+ (CGSize)convertVideoSize:(CGSize)videoSize ToViewSize:(CGSize)viewSize {
    if (videoSize.width == 0 && videoSize.height == 0) {
        return CGSizeZero;
    }
    //把相对短的边拉伸or缩小到viewSize的对应变的长度
    if (videoSize.width/videoSize.height > viewSize.width/viewSize.height) {
        //视频size比较宽
        CGFloat scale = viewSize.height/videoSize.height;
        return CGSizeMake(videoSize.width*scale, videoSize.height*scale);
    }
    else {
        //视频size比较长
        CGFloat scale = viewSize.width/videoSize.width;
        return CGSizeMake(videoSize.width*scale, videoSize.height*scale);
    }
}

@end
