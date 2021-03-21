//
//  WQAAppletsItem.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WQAAppletsItem : NSObject

- (instancetype)initWithConfig:(nullable NSDictionary *)config;

@property (nonatomic, copy) NSString *appletsID;
@property (nonatomic, copy, readonly) NSString *md5;
@property (nonatomic, copy, readonly) NSArray<NSString *> *entranceList;
@property (nonatomic, strong, readonly) NSNumber *size;
@end

NS_ASSUME_NONNULL_END
