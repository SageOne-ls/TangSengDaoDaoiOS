//
//  WKLanguageVM.m
//  WuKongBase
//
//  Created by tt on 2020/12/25.
//

#import "WKLanguageVM.h"
#import "WKLabelItemSelectCell.h"


@implementation WKLanguageVM

- (NSArray<NSDictionary *> *)tableSectionMaps {
    NSString *langue = [WKApp shared].config.langue;
    __weak typeof(self) weakSelf = self;
    return @[
        @{
            @"height":@(0.0f),
            @"items":@[
                    @{
                        @"class":WKLabelItemSelectModel.class,
                        @"label":@"繁體中文",
                        @"selected":@([langue isEqualToString:@"zh-Hant"]),
                        @"onClick":^{
                            [WKApp shared].config.langue = @"zh-Hant";
                            [weakSelf reloadData];
                        }
                    },
                    @{
                        @"class":WKLabelItemSelectModel.class,
                        @"label":@"English",
                        @"selected":@([langue isEqualToString:@"en"]),
                        @"onClick":^{
                            [WKApp shared].config.langue = @"en";
                            [weakSelf reloadData];
                        }
                    },
                    @{
                        @"class":WKLabelItemSelectModel.class,
                        @"label":@"日本語",
                        @"selected":@([langue isEqualToString:@"ja"]),
                        @"onClick":^{
                            [WKApp shared].config.langue = @"ja";
                            [weakSelf reloadData];
                        }
                    },
                    @{
                        @"class":WKLabelItemSelectModel.class,
                        @"label":@"Tiếng Việt",
                        @"selected":@([langue isEqualToString:@"vi"]),
                        @"onClick":^{
                            [WKApp shared].config.langue = @"vi";
                            [weakSelf reloadData];
                        }
                    }
            ],
        }
    ];
}

@end
