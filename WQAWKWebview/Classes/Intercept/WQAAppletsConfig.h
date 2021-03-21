//
//  WQAAppletsConfig.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/12.
//

#import <Foundation/Foundation.h>
#import <WQAAppletsItem.h>
#import <WQAWebCommonDefine.h>

NS_ASSUME_NONNULL_BEGIN

@interface WQAAppletsConfig : NSObject


@property (nonatomic, copy, readonly) NSString *appName;
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, copy, readonly) NSString *lastModify;
@property (nonatomic, copy, readonly) NSString *md5;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSString *, WQAAppletsItem *> *appletsInfoList;

- (WQAAppletsItem *)getItemConfig:(NSString *)appId;
- (WQAAppletsItem *)getItemConfigWithURL:(NSURL *)url;
- (instancetype)initWithjsonData:(NSData *)jsonData;
+ (instancetype)configWithFile:(NSString *)path;
@end

NS_ASSUME_NONNULL_END
