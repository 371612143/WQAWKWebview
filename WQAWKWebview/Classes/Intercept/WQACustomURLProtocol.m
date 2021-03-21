//
//  WQACustomURLProtocol.m
//  CUBE
//
//  Created by matthew on 2019/5/25.
//

#import "WQACustomURLProtocol.h"
#import <WQAWebEnvironment.h>
#import "WQAResourceManager.h"
#import "WQAOfflineUtil.h"

#define DYNAMIC_SUFFIX  @"js.html"
#define UserAgentKey    @"User-Agent"
#define HttpResponseHeader @{@"Access-Control-Allow-Origin": @"*"}

 
@interface WQACustomURLProtocol()<NSURLSessionDataDelegate>
@property(nonatomic, strong) NSURLSessionDataTask *task;
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong) NSURLResponse *response;
@property(nonatomic, strong) NSMutableData *bytesBuffer;
@end

@implementation WQACustomURLProtocol


+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (!request.allHTTPHeaderFields[UserAgentKey])
        return NO;
    if ([request.HTTPMethod isEqualToString:@"POST"])
        return YES;
    if ([request.HTTPMethod isEqualToString:@"GET"])
        return YES;
    return NO;
}

- (BOOL)_needCacheDisk {
    if (WQAEnvironmentInstance.webviewCacheLevel == WQACacheStateOff)
        return NO;
    if ([self.request.URL.path hasSuffix:DYNAMIC_SUFFIX])
        return NO;
    if ([self.request.URL.absoluteString isEqualToString:self.request.mainDocumentURL.absoluteString])
        return YES;
    return [WQAEnvironmentInstance.staticResourceList containsObject:self.request.URL.pathExtension];
        
}
 
- (void)startLoading {
    NSURL *url = self.request.URL;
    NSString *appletsID = [WQAOfflineUtil appletsIDFromRequest:self.request];
    BOOL needCacheDisk = [self _needCacheDisk];
    NSString *filePath = [[WQAResourceManager sharedInstance] resourceDestPath:url mainDocumentURL:self.request.mainDocumentURL appletsID:appletsID];
    
    if (needCacheDisk) {
        WQAURLProtocolCacheData *cacheData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        if (cacheData.data.length > 0 && [cacheData.response isKindOfClass:[NSHTTPURLResponse class]] && cacheData.response.statusCode == 200) {
            [self onReciveData:@{@"data":cacheData.data, @"response":cacheData.response}];
            logWebInfo([NSString stringWithFormat:@"WQACustomURLProtocol use static resource:%@ size:%lud", url.absoluteString, cacheData.data.length]);
            return;
        }
    }
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    self.task = [self.session dataTaskWithRequest:self.request];
    [self.task resume];
    
}

- (void)onReciveData:(NSDictionary *)params {
    [self callClientAction:WQAURLProtocolActionRecvResponse data:params[@"response"]];
    [self callClientAction:WQAURLProtocolActionLoadData data:params[@"data"]];
    [self callClientAction:WQAURLProtocolActionDidSuccess data:nil];
}

- (void)onReciveError:(NSError *)error {
    [self callClientAction:WQAURLProtocolActionDidFaild data:error];
}

- (void)stopLoading {
    [self.task cancel];
    self.task = nil;
    [self.session invalidateAndCancel];
    self.session = nil;
    self.response = nil;
    self.bytesBuffer = nil;
}

- (void)dealloc {
    if (self.session) {
        [self.task cancel];
        self.task = nil;
        [self.session invalidateAndCancel];
        self.session = nil;
    }
    self.response = nil;
    self.bytesBuffer = nil;
}

//前端提出资源域名替换问题
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSString *replaceUrl = request.URL.absoluteString;
    NSMutableURLRequest *mrequest = [[NSMutableURLRequest alloc] initWithURL:request.URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:request.timeoutInterval];
    mrequest.mainDocumentURL = request.mainDocumentURL;
    mrequest.HTTPMethod = request.HTTPMethod;
    //[request mutableCopy].allHTTPHeaderFields = header; //不会成功
    NSMutableDictionary *header = [[NSMutableDictionary alloc] initWithDictionary:request.allHTTPHeaderFields];
//    [header removeObjectForKey:@"If-None-Match"];
//    [header removeObjectForKey:@"If-Modified-Since"];
    mrequest.allHTTPHeaderFields = header;
    
    if (![replaceUrl isEqualToString:request.URL.absoluteString]) {
        mrequest.URL = [NSURL URLWithString:replaceUrl];
    }
    NSString *postId = nil;
    //UIWebview postbody不会丢失 wkwebview会
    if ([mrequest.HTTPMethod isEqualToString:@"POST"]) {
        if (mrequest.allHTTPHeaderFields[@"postId"]) { //wkwebview postbody丢失
            postId = mrequest.allHTTPHeaderFields[@"postId"];
            id httpBody = [WQAEnvironmentInstance HTTPPostBodyForKey:mrequest.allHTTPHeaderFields[@"postId"]];
            if ([httpBody isKindOfClass:[NSString class]])
                mrequest.HTTPBody = [(NSString *)httpBody dataUsingEncoding:NSUTF8StringEncoding];
            else if ([httpBody isKindOfClass:[NSData class]])
                mrequest.HTTPBody = httpBody;
            else if ([httpBody isKindOfClass:[NSArray class]] || [httpBody isKindOfClass:[NSDictionary class]]){
                NSString *bodyString = [NSString stringWithFormat:@"%@", httpBody];
                if (bodyString)
                    mrequest.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
            }
        }
        else {  //UIWebview postbody不会丢失
            if (request.HTTPBody)
                mrequest.HTTPBody = request.HTTPBody;
            else
                mrequest.HTTPBodyStream = request.HTTPBodyStream;
        }
    }
    
    if (mrequest.URL.absoluteString) {  //WEBVIEW下载添加一个参数
        NSURLComponents *components = [NSURLComponents componentsWithURL:mrequest.URL resolvingAgainstBaseURL:YES];
        NSMutableArray *querys = [NSMutableArray arrayWithArray:components.queryItems];
        if (WQAEnvironmentInstance.overWallSwitch > 0)
            [querys addObject:[NSURLQueryItem queryItemWithName:@"WQAOfflineRes" value:@"1"]];
        if (postId.length > 0) //post 多次下载问题，两个url相同post参数不同。
            [querys addObject:[NSURLQueryItem queryItemWithName:@"WQA_offline_postid" value:postId]];
        if (querys.count > 0)
            components.queryItems = querys;
        mrequest.URL = [components URL];
    }
    
    return mrequest; 
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    self.bytesBuffer = [NSMutableData new];
    self.response = response;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    [self.bytesBuffer appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error != nil) {
        [self.client URLProtocol:self didFailWithError:error];
        logWebInfo([NSString stringWithFormat:@"WQACustomURLProtocol didCompleteWithError:%@", self.request.URL.absoluteString]);
    }
    else {
        WQAURLProtocolCacheData *cacheData = [[WQAURLProtocolCacheData alloc] init];
        cacheData.data = [self.bytesBuffer copy];
        cacheData.response = (NSHTTPURLResponse *)self.response;
        NSString *appletsID = [WQAOfflineUtil appletsIDFromRequest:self.request];
        NSString *filePath = [[WQAResourceManager sharedInstance] resourceDestPath:self.request.URL mainDocumentURL:self.request.mainDocumentURL appletsID:appletsID];
        if (cacheData.response.statusCode == 200 && cacheData.data.length > 0 && [self _needCacheDisk]) {
            [NSKeyedArchiver archiveRootObject:cacheData toFile:filePath];
            logWebInfo([NSString stringWithFormat:@"WQACustomURLProtocol cache static resource:%@ size:%lud", self.request.URL.absoluteString, cacheData.data.length]);
        }
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)callClientAction:(WQAURLProtocolAction)action data:(id)data {
    switch (action) {
        case WQAURLProtocolActionRecvResponse:
        {
            [self.client URLProtocol:self didReceiveResponse:data cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        }
            break;
        case WQAURLProtocolActionLoadData:
        {
            [self.client URLProtocol:self didLoadData:data];
        }
            break;
        case WQAURLProtocolActionDidSuccess:
        {
            [self.client URLProtocolDidFinishLoading:self];
        }
            break;
        case WQAURLProtocolActionDidFaild:
        {
            [self.client URLProtocol:self didFailWithError:data];
        }
            break;
    }
}

@end

