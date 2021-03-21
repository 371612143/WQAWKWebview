//
//  WQAWebEnvironment.h
//  WQAWebview
//
//  Created by matthew on 2019/3/26.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "WQAWebCommonDefine.h"
@class WQAWkWebview;

typedef NS_ENUM(NSInteger, WQACacheState) {
    WQACacheStateOff = 0,  //关闭
    WQACacheForbiddenIOS12 = 1, //屏蔽ios12系统
    WQACacheStateOffLine = 2,  //全量缓存
    WQACacheWebviewPoolOnly = 3, //只打开webview池
    WQACacheWebviewCleanMode = 4, //清理缓存
};

@interface WQAWebEnvironment : NSObject

SINGLE_DECL(WQAWebEnvironment)
@property (nonatomic, strong)NSString *WQAUpdateAppID;    //app更新id
@property (nonatomic, strong, readonly)WKUserScript *ajaxHookScript;
@property (nonatomic, strong, readonly)WKUserScript *jsBridgeScript;
//防封禁相关配置 需要时才填写
@property (nonatomic, assign)WQACacheState webviewCacheLevel;  //页面缓存总开关，启动一次app只能设置一次
@property (nonatomic, strong)NSArray *cacheTrustDomains;
@property (nonatomic, assign)NSInteger overWallSwitch;  //域名封禁通道选择开关
@property (nonatomic, strong, readonly)NSArray *staticResourceList;
@property (nonatomic, strong)void(^WQAReportStateBlock)(NSString *eventId, NSDictionary *event);  //hive统计代理
@property (nonatomic, strong)WQAWkWebview *(^createWKWebviewBlock)(void);

- (void)addUrlsToBlackList:(NSArray<NSString *> *)urls;
- (void)WQAReport:(NSString *)eventId event:(NSDictionary *)event;
- (void)addHTTPPostBody:(id)body postId:(NSString *)postId;
- (id)HTTPPostBodyForKey:(NSString *)key;
- (BOOL)isForbidenIntercept:(NSString *)url;
//webview池相关
- (WQAWkWebview *)webviewInstanceByPool;
- (void)recycleWebview:(WQAWkWebview *)webview;
- (void)updateWebviewCountLimit:(NSInteger)limit;
@end

