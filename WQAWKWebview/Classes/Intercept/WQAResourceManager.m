//
//  WQAResourceManager.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/4.
//  Copyright © 2019 matthew. All rights reserved.
//


#import <WQAWebEnvironment.h>
#import "WQAResourceManager.h"
#import "WQAOfflineUtil.h"

@interface WQAResourceManager()
@property (nonatomic, strong)WQAResourceDownloader *resourceDownloader;
@property (atomic, strong)WQAAppletsConfig *appletsConfig;
@property (nonatomic, strong)NSTimer *downLoadTimer;
@property (nonatomic, strong)WQADiskCache *diskCache;
@property (nonatomic, strong)dispatch_queue_t report_queue;
@end

@implementation WQAResourceManager

SINGLETON_IMP(WQAResourceManager)

- (instancetype)init {
    if (self = [super init]) {
        _diskCache = [WQADiskCache new];
        _appletsConfig = [WQAAppletsConfig configWithFile:[WQADiskCache configFilePath]];
        _report_queue = dispatch_queue_create("WQAwebview_cache_queue", DISPATCH_QUEUE_SERIAL);
        _resourceDownloader = [[WQAResourceDownloader alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.downLoadTimer invalidate];
    self.downLoadTimer = nil;
}

- (void)clearAllCache {
    [self.diskCache clearAllCache];
    self.appletsConfig = [WQAAppletsConfig new];
}

- (CGFloat)diskCacheSize {
    return [self.diskCache diskCacheSize];
}

- (NSString *)resourceDestPath:(NSURL *)resourceURL mainDocumentURL:(NSURL *)mainDocumentURL appletsID:(NSString *)appletsID {
    return [self.diskCache resourceDestPath:resourceURL mainDocumentURL:mainDocumentURL appletsID:appletsID];
}

- (void)downloadAppletsResourece:(NSURLRequest *)requset
                 destinationPath:(NSString *)destinationPath
               completionHandler:(WQADownloadCompletionHandler)completionHandler
                 redirtctHandler:(WQADownloadRedirtctHandler)redirtctHandler {
    [self.resourceDownloader downloadResourcB:requset destinationPath:destinationPath progressHandler:^(float progress) {

    } completionHandler:^(BOOL success, NSData *data, NSHTTPURLResponse *response) {
        if (completionHandler)
            completionHandler(success, data, response);
    }
    redirtctHandler:^(NSURLRequest *request, NSURLResponse *response) {
        if (redirtctHandler)
            redirtctHandler(request, response);
    }];
}


- (void)cancelDownLoad:(NSString *)url {
    if (url.length == 0)
        return;
    [self.resourceDownloader cancelDownloadUrl:url];
}

#pragma mark download-diff config and preload, remove disk cache
- (void)downloadConfigFile {
    if (!_appletsConfigUrl || _appletsConfigUrl.length == 0)
        return;
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timeInterval = [date timeIntervalSince1970];
    
    NSURLComponents *components = [NSURLComponents componentsWithURL:[NSURL URLWithString:_appletsConfigUrl] resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *queryItems = [NSMutableArray arrayWithArray:components.queryItems];
    [queryItems addObject:[NSURLQueryItem queryItemWithName:@"timestamp" value:@(timeInterval).stringValue]];
    if (_appletsConfig.md5) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:@"lastmodify" value:_appletsConfig.lastModify]];
    }
    if (queryItems.count > 0)
        components.queryItems = queryItems;
    NSURL *componentsURL = components.URL;
    
    WEAK_SELF_DECLARED
    [self.resourceDownloader downloadResource:componentsURL.absoluteString destinationPath:[WQADiskCache configFilePath] progressHandler:nil completionHandler:^(BOOL success, NSData *data, NSHTTPURLResponse *response) {
        STRONG_SELF_BEGIN
        if (success && data) {
            WQAAppletsConfig *netConfig = [[WQAAppletsConfig alloc] initWithjsonData:data];
            [strongSelf diffConfig:netConfig];
        }
        else {
            NSMutableDictionary *paramDict = [NSMutableDictionary new];
            [paramDict setObject:strongSelf.appletsConfigUrl ? : @"" forKey:@"url"];
            [paramDict setObject:@(response.statusCode).stringValue forKey:@"code"];
            [paramDict setObject:@(0).stringValue forKey:@"sucess"];
            WQAWebReport(WQAEventDownloadConfig, paramDict);
        }
        STRONG_SELF_END
    }];
}

- (void)diffConfig:(WQAAppletsConfig *)newConfig {
    if (newConfig.lastModify == self.appletsConfig.lastModify)
        return;
    WQAAppletsConfig *prevConfig = self.appletsConfig;
    _appletsConfig = newConfig;
    
    //确定config中zip的增量配置
    for (NSString *appletsID in _appletsConfig.appletsInfoList.allKeys) {
        WQAAppletsItem *obj = _appletsConfig.appletsInfoList[appletsID];
        WQAAppletsItem *diskItem = prevConfig.appletsInfoList[appletsID];
        
        if (!diskItem) {
            [self _preloadMainDocument:obj];
        }
        else if (![obj.md5 isEqualToString:diskItem.md5]) {
            [self.diskCache removeApplets:diskItem appletsID:appletsID];
        }
    }
    
    //确定config中zip的需要删除的数据
    for (NSString *appletsID in prevConfig.appletsInfoList.allKeys) {
        if (!_appletsConfig.appletsInfoList[appletsID])
            [self.diskCache removeApplets:prevConfig.appletsInfoList[appletsID] appletsID:appletsID];
    }
}

- (void)_preloadMainDocument:(WQAAppletsItem *)item {
    for (NSString *documentUrl in item.entranceList) {
        if (![documentUrl isKindOfClass:[NSString class]] || documentUrl.length == 0)
            break;
        NSString *filePath = [self.diskCache resourceDestPath:[NSURL URLWithString:documentUrl] mainDocumentURL:[NSURL URLWithString:documentUrl] appletsID:item.appletsID];
        [self.resourceDownloader downloadResource:documentUrl destinationPath:filePath progressHandler:^(float progress) {
            
        } completionHandler:^(BOOL success, NSData *data, NSHTTPURLResponse *response) {
            
        }];

    }
}

- (void)setAppletsConfigUrl:(NSString *)appletsConfigUrl {
    //需要对配置文件做域名替换，避免被外网屏蔽
    _appletsConfigUrl = appletsConfigUrl;
    [self downloadConfigFile];
    if (_downLoadTimer) {
        [_downLoadTimer invalidate];
        _downLoadTimer = nil;
    }
    _downLoadTimer = [NSTimer scheduledTimerWithTimeInterval:10*60 target:self selector:@selector(downloadConfigFile) userInfo:nil repeats:YES];
    
}
@end
