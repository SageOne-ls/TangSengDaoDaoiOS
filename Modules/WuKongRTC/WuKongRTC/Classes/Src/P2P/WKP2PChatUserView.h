//
//  WKP2PChatUserView.h
//  WuKongRTC
//
//  Created by tt on 2022/10/5.
//

#import <UIKit/UIKit.h>
#import "WKRTCConst.h"
#import "WKRTCConstants.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKP2PChatUserView : UIView


-(instancetype) initWithViewType:(WKRTCViewType)viewType callType:(WKRTCCallType)callType;

@property(nonatomic,strong) UIImageView *userAvatarImgView;
@property(nonatomic,strong) UILabel *nameLbl;
@property(nonatomic,strong) UILabel *statusLbl;

@property(nonatomic,assign) WKRTCStatus status;
@property(nonatomic,assign) WKRTCCallType callType;


@end

NS_ASSUME_NONNULL_END
