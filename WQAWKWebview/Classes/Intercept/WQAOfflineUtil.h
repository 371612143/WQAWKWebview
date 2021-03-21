//
//  WQAOfflineUtil.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/8/14.
//

#import <Foundation/Foundation.h>
#import <WQAResourceManager.h>

#define WQACacheOfflineSwitch
#define WQAResourceInstance [WQAResourceManager sharedInstance]

#define HttpResponseHeader @{@"Access-Control-Allow-Origin": @"*"}

NS_ASSUME_NONNULL_BEGIN

@interface WQAOfflineUtil : NSObject
+ (NSString *)appletsIDFromURL:(NSURL *)url;
+ (NSString *)appletsIDFromRequest:(NSURLRequest *)request;
+ (NSURL *)urlByDeletingParameters:(NSURL *)url;
+ (void)switchOnOfflineCache:(NSString *)offlineConfigUrl;   //设置离线配置文件url后会开启页面离线化相关功能
+ (void)turnOffCache;
@end

NS_ASSUME_NONNULL_END
