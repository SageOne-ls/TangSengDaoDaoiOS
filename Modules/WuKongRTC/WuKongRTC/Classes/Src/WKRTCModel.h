//
//  WKRTCModel.h
//  WuKongRTC
//
//  Created by tt on 2022/9/16.
//

#import <Foundation/Foundation.h>
#import <WuKongBase/WuKongBase.h>
NS_ASSUME_NONNULL_BEGIN

@interface WKCreateRoomReq : NSObject

@property(nonatomic,nullable,copy) NSString *name; // 房间名称（非必填）
@property(nonatomic,strong)NSArray *uids; // 房间成员uids
@property(nonatomic,copy) NSString *channelID; // 频道ID (非必填）
@property(nonatomic,assign) uint8_t channelType; // 频道类型 (非必填）
@end

@interface WKCreateRoomResp : WKModel

@property(nonatomic,copy) NSString *roomID;
//@property(nonatomic,copy) NSString *token;

@end

NS_ASSUME_NONNULL_END
