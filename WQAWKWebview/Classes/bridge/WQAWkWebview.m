//
//  WQACommonWKWebView.m
//  WQACommonWkWebview
//
//  Created by matthew on 2019/3/20.
//  Copyright © 2019年 matthew. All rights reserved.
//

#import "WQAWkWebview.h"
#import "WQABridgeInvokeItem.h"

#import "WQAWebCommonDefine.h"
#import "WQAWebEnvironment.h"
#import "ObjcHelpFunc.h"
#import "WKProcessPool+WQASharedProcessPool.h"
#if __has_include(<WQAOfflineUtil.h>)
#import <WQAOfflineUtil.h>
#import <WKWebView+Extension.h>
#endif
@interface WQAWkWebview()

@property (nonatomic, copy) NSArray<NSString *> *currentTrustDomains;
@property (nonatomic, copy) NSArray<NSString *> *blackListDomains;
@property (nonatomic, copy) NSString *currentRedirectUrl;
@property (nonatomic, assign) BOOL isTrustDomain;
@property (nonatomic, assign) BOOL hasReportLoadState;  //是否上报页面打开情况
@property (nonatomic, assign) NSInteger httpStatusCode;  //是否上报页面打开情况
@property (nonatomic, assign) int64_t startLoadTimestamp;
@end

@implementation WQAWkWebview

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    WKPreferences *preference = [[WKPreferences alloc] init];
    configuration.preferences = preference;
    preference.javaScriptEnabled = YES;
    if (WQAEnvironmentInstance.webviewCacheLevel != WQACacheStateOff)
        configuration.processPool = [WKProcessPool sharedInstance];
    
    if (self = [super initWithFrame:frame configuration:configuration]) {
        [self setUpWebview];
        [self.configuration.userContentController addUserScript:[WQAWebEnvironment sharedInstance].jsBridgeScript];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    if (self = [self initWithFrame:frame configuration:config]) {
        [self setUpWebview];
    }
    return self;
}

- (void)setUpWebview {
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.backgroundColor = [UIColor whiteColor];
    self.opaque = NO;
    [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    self.navigationDelegate = self;
    self.UIDelegate = self;
}

-(void)dealloc {
    [self _handLoadFinished:-1 result:@"3" loadUrl:self.URL];
}

- (void)setTrustDomains:(NSArray<NSString *> *)trustDomains blackDomains:(NSArray<NSString *> *)blackDomains 
            redirectUrl:(NSString *)redirectUrl {
    NSMutableArray *trustList = [NSMutableArray arrayWithArray:trustDomains];
    //处理替换后的域名
    if ([_WQANavigationDelegate respondsToSelector:@selector(webview:getHostReplaceUrl:)]) {
        for (NSString *host in trustDomains) {
            NSURL *replaceUrl = [_WQANavigationDelegate webview:self getHostReplaceUrl:[NSURL URLWithString:host]];
            if (replaceUrl.absoluteString > 0 && ![host isEqualToString:replaceUrl.absoluteString]) {
                [trustList addObject:replaceUrl.absoluteString];
            }
        }
    }
    
    self.currentTrustDomains = trustList;
    self.blackListDomains = blackDomains;
    self.currentRedirectUrl = redirectUrl;
}

- (WKNavigation *)loadRequest:(NSURLRequest *)request {
    NSURL *replaceURL = request.URL;
    //域名替换防封禁
    if (replaceURL.absoluteString && [self.WQANavigationDelegate respondsToSelector:@selector(webview:getHostReplaceUrl:)]) {
        replaceURL = [self.WQANavigationDelegate webview:self getHostReplaceUrl:replaceURL];
    }
    if (replaceURL.absoluteString.length == 0 || [request.URL.absoluteString isEqualToString:WQAWeb_BLANK_URL]) {
        _orginLoadUrl = replaceURL;
        return [super loadRequest:request];
    }

#ifdef WQACacheOfflineSwitch
    WQAAppletsItem *item = [[WQAResourceManager sharedInstance].appletsConfig getItemConfigWithURL:request.URL];
    NSURLComponents *components = [[NSURLComponents alloc] initWithURL:replaceURL resolvingAgainstBaseURL:NO];
    NSMutableArray *queryItems = [NSMutableArray arrayWithArray:components.queryItems];
    if (item.appletsID) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"appletsID" value:item.appletsID]];
    }
    if (queryItems.count > 0) {
       components.queryItems = queryItems;
    }
    replaceURL = components.URL;
    if (![self checkWhiteList:replaceURL] && _currentRedirectUrl.length > 0) {
        //不在白名单则在对应的前端页面进行过滤
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", _currentRedirectUrl, replaceURL];
        replaceURL = [[NSURL alloc] initWithString:urlStr];
    }
    _orginLoadUrl = replaceURL;
#else
    //检查白名单系统
    if (![self checkWhiteList:replaceURL] && _currentRedirectUrl.length > 0) {
        //不在白名单则在对应的前端页面进行过滤
        NSString *urlStr = [NSString stringWithFormat:@"%@%@", _currentRedirectUrl, replaceURL];
        replaceURL = [[NSURL alloc] initWithString:urlStr];
    }
    _orginLoadUrl = replaceURL;
#endif
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:replaceURL];
    return [super loadRequest:req];
}

- (BOOL)checkWhiteList:(NSURL *)url {
   __block BOOL isTrust = NO;
     NSString *host = url.host;
    for (NSString *obj in self.currentTrustDomains) {
        if ([obj hasSuffix:host]) {
            isTrust = YES;
            break;
        }
    };
    //黑名单(和缓存的黑名单不一样，历史代码缓存的黑名单也可以阻止js调用)
    for (NSString *obj in self.blackListDomains) {
        if ([host hasSuffix:obj]) {
            isTrust = NO;
            break;
        }
    };
    self.isTrustDomain = isTrust;
    return isTrust;
}

- (BOOL)canGoBack {
#ifdef WQACacheOfflineSwitch
    if ([self.backForwardList.backItem.URL.absoluteString isEqualToString:WQAWeb_BLANK_URL])
        return NO;
#endif
    return [super canGoBack];
}

- (void)endReuseTrace {
    [self _handLoadFinished:-1 result:@"3" loadUrl:self.URL];
    [self removeFromSuperview];
    [self stopLoading];
    self.WQANavigationDelegate = nil;
    self.UIDelegate = nil;
    self.navigationDelegate = nil;
#ifdef WQACacheOfflineSwitch
    [self clearBrowseHistory];
#endif
    _poolResuedFlag = 1;
    [self.configuration.userContentController removeAllUserScripts];
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:WQAWeb_BLANK_URL]]];
}


- (void)prepaeForReuse {
#ifdef WQACacheOfflineSwitch
    [self clearBrowseHistory];
#endif
    self.hasReportLoadState = NO;
    self.isTrustDomain = false;
    _orginLoadUrl = nil;
    self.UIDelegate = self;
    self.navigationDelegate = self;
    [self.configuration.userContentController addUserScript:[WQAWebEnvironment sharedInstance].jsBridgeScript];
}

- (void)_handLoadFinished:(NSInteger)code result:(NSString *)result loadUrl:(NSURL *)loadUrl {
    if (self.hasReportLoadState)
        return;
    self.hasReportLoadState = YES;
    NSString *url = loadUrl.absoluteString;
    if (url.length == 0 || [url isEqualToString:WQAWeb_BLANK_URL])  //无效页面，用来将webview置透明,不统计
        return;
    url = [NSString stringWithFormat:@"%@://%@%@", loadUrl.scheme, loadUrl.host, loadUrl.path];
    if (url.length <= 3)
        return;
    int64_t duration = [[NSDate date] timeIntervalSince1970] * 1000 - self.startLoadTimestamp;
    NSString *loadTime = @(duration).stringValue;
    
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timeInterval = [date timeIntervalSince1970];
    NSString *time = [NSString stringWithFormat:@"%.0f", timeInterval];
    
    NSString *httpcode = @(_httpStatusCode).stringValue;
    NSString *errorCode = @(code).stringValue;
    NSMutableDictionary *reportInfo = [[NSMutableDictionary alloc] initWithDictionary:@{@"http_code":httpcode, @"result":result, @"url":url, @"load_time":loadTime, @"time": time}];
    if (code != 0) {
        [reportInfo setObject:errorCode forKey:@"error_code"];
    }
    NSString *cacheLevel = (self.isTrustDomain && ![WQAEnvironmentInstance isForbidenIntercept:url]) ? @(WQAEnvironmentInstance.webviewCacheLevel).stringValue : @"0";
    if ([WQAWebEnvironment sharedInstance].webviewCacheLevel == WQACacheWebviewPoolOnly){
        cacheLevel = @"5";
    }
    [reportInfo setObject:[UIDevice currentDevice].systemName forKey:@"platform"];
    [reportInfo setObject:[UIDevice currentDevice].systemVersion ?: @"" forKey:@"os"];
    [reportInfo setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] ?: @"" forKey:@"version"];
    [reportInfo setObject:cacheLevel forKey:@"cache_level"];
    WQAWebReport(WQAStatisticsEventWebViewLoad, reportInfo)
}

- (UIViewController *)_parentViewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}
- (BOOL)_isDelegateVCShow {
    UIViewController *parentVC = [self _parentViewController];
    if (parentVC && parentVC.isViewLoaded && parentVC.view.window) {
        return YES;
    }
    return NO;
}

#pragma mark -- WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    static NSString *kRPCUrlPath = @"/njkwebviewprogressproxy/complete";
    NSURL *requestUrl = navigationAction.request.URL;
    NSString *urlString = bgf_URLDecoding(requestUrl.absoluteString);
    
    if ([urlString isEqualToString:WQAWeb_BLANK_URL]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    WEAK_SELF_DECLARED
    void (^customHandler)(WKNavigationActionPolicy) = ^(WKNavigationActionPolicy policy){
        STRONG_SELF_BEGIN
        if (policy == WKNavigationActionPolicyAllow) {
            strongSelf.startLoadTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
            strongSelf.hasReportLoadState = NO;
                //在页面跳转时检查白名单，封禁JSAPI
            [self checkWhiteList:requestUrl];
#ifdef WQACacheOfflineSwitch
            if (strongSelf.isTrustDomain && ![WQAEnvironmentInstance isForbidenIntercept:urlString]) {
                [webView.configuration.userContentController addUserScript:[WQAWebEnvironment sharedInstance].ajaxHookScript];
                [WQAOfflineUtil switchOnOfflineCache:[WQAResourceManager sharedInstance].appletsConfigUrl];
            }
            else {
                [WQAOfflineUtil turnOffCache];
//                [webView.configuration.userContentController removeAllUserScripts];
            }
#endif
        }
        decisionHandler(policy);
        STRONG_SELF_END
    };

    //appstore相关
    if (([urlString hasPrefix:@"itms-appss://"] || [urlString hasPrefix:@"itms-apps://"]) &&
        [urlString rangeOfString:[NSString stringWithFormat:@"app/id%@", [WQAWebEnvironment sharedInstance].WQAUpdateAppID]].length != 0) {
        [[UIApplication sharedApplication] openURL:[navigationAction.request URL]];
        customHandler(WKNavigationActionPolicyCancel);
        return;
    }
    // 邮件mailto前缀
    if ([navigationAction.request.URL.scheme isEqualToString:@"mailto"]) {
        if ([[UIApplication sharedApplication] canOpenURL:navigationAction.request.URL]) {
            [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
            customHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    if ([requestUrl.path isEqualToString:kRPCUrlPath]) {
        customHandler(WKNavigationActionPolicyCancel);
        return;
    }
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [_WQANavigationDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:customHandler];
    }
    else if (decisionHandler) {
        customHandler(WKNavigationActionPolicyAllow);
    }
}

-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [_WQANavigationDelegate webView:webView didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [_WQANavigationDelegate webView:webView didFailNavigation:navigation withError:error];
    }
    
    [self _handLoadFinished:error.code result:@"2" loadUrl:self.URL];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [_WQANavigationDelegate webView:webView didFinishNavigation:navigation];
    }
    [self _handLoadFinished:0 result:@"1" loadUrl:self.URL];
    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if (navigationResponse && navigationResponse.response) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
        _httpStatusCode = response.statusCode;
    }
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [_WQANavigationDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }else if (decisionHandler){
        decisionHandler (WKNavigationResponsePolicyAllow);
    }
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [_WQANavigationDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [_WQANavigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
    //在didFailProvisionalNavigation时， self.url = nil，一般在断网的情况下容易出现这个case
    NSURL *url = error.userInfo[NSURLErrorFailingURLErrorKey];
    [self _handLoadFinished:error.code result:@"2" loadUrl:url];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    if([_WQANavigationDelegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]){
        [_WQANavigationDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

-(void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
        [_WQANavigationDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }else{
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    if ([self.WQANavigationDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        return [self.WQANavigationDelegate webViewWebContentProcessDidTerminate:webView];
    }
    logWebInfo(@"webViewWebContentProcessDidTerminate");
    [self reload];
}

#pragma mark -- WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:alertAction];
    if ([self _isDelegateVCShow]) {
        [[self _parentViewController] presentViewController:alertController animated:YES completion:nil];
    } else {
        completionHandler();
    }
    
    
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(BOOL))completionHandler {
    UIAlertAction *alertActionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }];
    UIAlertAction *alertActionOK = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:alertActionCancel];
    [alertController addAction:alertActionOK];
    if ([self _isDelegateVCShow]) {
        [[self _parentViewController] presentViewController:alertController animated:YES completion:nil];
    } else {
        completionHandler(NO);
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(nonnull NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alertController.textFields.firstObject;
        completionHandler(textField.text);
    }]];
    if ([self _isDelegateVCShow]) {
        [[self _parentViewController] presentViewController:alertController animated:YES completion:nil];
    } else {
        completionHandler(@"");
    }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if ([_WQANavigationDelegate respondsToSelector:@selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)]) {
        return [_WQANavigationDelegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    }
    return nil;
}
@end
