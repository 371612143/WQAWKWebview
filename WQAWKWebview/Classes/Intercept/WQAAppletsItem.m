//
//  WQAAppletsItem.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/12.
//

#import "WQAAppletsItem.h"
#import "WQADiskCache.h"
#import "WQAOfflineUtil.h"

@interface WQAAppletsItem()
@property (nonatomic, strong) NSDictionary *itemConfig;
@end

@implementation WQAAppletsItem

- (instancetype)initWithConfig:(NSDictionary *)config {
    if (self = [super init]) {
        _itemConfig = config;
    }
    return self;
}

- (NSNumber *)size {
    return [NSNumber numberWithInteger:[_itemConfig[@"size"] integerValue]];
}


- (NSString *)md5 {
    return _itemConfig[@"md5"];
}

- (NSArray<NSString *> *)entranceList {
    if ([_itemConfig[@"url"] isKindOfClass:[NSArray class]])
        return _itemConfig[@"url"];
    else if ([_itemConfig[@"url"] isKindOfClass:[NSString class]])
        return [NSArray arrayWithObjects:_itemConfig[@"url"], nil];
    return nil;
}

@end
