//
//  WQACommonWkWebview.h
//  WQACommonWkWebview
//
//  Created by matthew on 2019/3/19.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class WQAWkWebview;

@protocol WQANavigationDelegate <WKNavigationDelegate>
@required
//防封禁相关逻辑，替换url的逻辑由各个业务实现
- (NSURL *)webview:(WQAWkWebview *)webview getHostReplaceUrl:(NSURL *)requestUrl;
@optional
-(WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures;
@end

@interface WQAWkWebview : WKWebView<WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, weak)id<WQANavigationDelegate> WQANavigationDelegate;
@property (nonatomic, assign, readonly)BOOL isTrustDomain;
@property (nonatomic, strong, readonly)NSURL* orginLoadUrl;  //替换域名后真正load的原始url
@property (nonatomic, assign, readonly)NSInteger poolResuedFlag;  //是否webviewpool重复使用
- (void)endReuseTrace;
- (void)prepaeForReuse;
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration;
- (void)setTrustDomains:(NSArray<NSString *> *)trustDomains blackDomains:(NSArray<NSString *> *)blackDomains
            redirectUrl:(NSString *)redirectUrl;

@end

