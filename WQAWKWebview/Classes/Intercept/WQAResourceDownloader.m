//
//  AFHttpResourceDownloader.m
//  BSConnection
//
//  Created by matthew on 2018/4/20.
//

#import "WQAResourceDownloader.h"
#import <WQAWebCommonDefine.h>
#import "WQADiskCache.h"
#import <AFNetworking/AFNetworking.h>
#import <CommonCrypto/CommonDigest.h>

#define WQA_RES_DATA_DIR  @"WQAResourceTempData"
#define WQA_RES_DOWNLOADER       @"WQAResourc-http"

@implementation WQAURLProtocolCacheData
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.data forKey:NSStringFromSelector(@selector(data))];
    [aCoder encodeObject:self.response forKey:NSStringFromSelector(@selector(response))];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self != nil) {
        self.data = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(data))];
        self.response = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(response))];
    }
    return self;
}

@end

@interface WQADownloadItem : NSObject
@property (nonatomic,copy)   NSString* tmpFilePath;
@property (nonatomic,copy)   NSString* desFilePath;
@property (nonatomic,assign) NSUInteger thisTimeDownloadExpectBytes;
@property (nonatomic,assign) NSUInteger lastTimeDownloadBytes;
@property (nonatomic,strong) NSMutableData* bytesBuffer;
@property (nonatomic,strong) NSURLResponse* response;
@property (nonatomic,copy)   NSMutableArray<WQADownloadProgressHandler>  *progressHandlers;
@property (nonatomic,copy)   NSMutableArray<WQADownloadCompletionHandler> *completionHandlers;
@property (nonatomic,copy)   NSMutableArray<WQADownloadRedirtctHandler> *redirtctHandlers;
@property (nonatomic,strong) NSURLSessionDataTask* task;
@end

@implementation WQADownloadItem

- (instancetype)init {
    if (self = [super init]) {
        _progressHandlers = [NSMutableArray new];
        _completionHandlers = [NSMutableArray new];
        _redirtctHandlers = [NSMutableArray new];
    }
    return self;
}

- (void)addInvokeHandler:(WQADownloadCompletionHandler)completionHandler progressHandler:(WQADownloadProgressHandler)progressHandler
         redirtctHandler:(WQADownloadRedirtctHandler)redirtctHandler {
    if (completionHandler)
        [_completionHandlers addObject:completionHandler];
    if (progressHandler)
        [_progressHandlers addObject:progressHandler];
    if (redirtctHandler)
        [_redirtctHandlers addObject:redirtctHandler];
}

- (void)invokeRedirtctHandlers:(NSURLRequest *)request response:(NSHTTPURLResponse *)response {
    for (WQADownloadRedirtctHandler handler in self.redirtctHandlers) {
        handler(request, response);
    }
    
}

- (void)invokeCompletionHandlers:(BOOL)success data:(NSData *)data response:(NSHTTPURLResponse *)response {
    for (WQADownloadCompletionHandler handler in self.completionHandlers) {
        handler(success, data, response);
    }
}

- (void)invokeProgressHandlers:(float)progress {
    for (WQADownloadProgressHandler handler in self.progressHandlers) {
        handler(progress);
    }
}
@end

@interface WQAResourceDownloader ()
{
    dispatch_queue_t resourceDownloadSerialQueue;
}
@property (nonatomic,strong) NSString* resourceTempFileDir;
@property (nonatomic,strong) NSMutableDictionary* resourceDownloadTasks;
@end

@implementation WQAResourceDownloader

- (instancetype)init
{
    if (self = [super init]) {
        resourceDownloadSerialQueue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
        _resourceTempFileDir = [self tmpFileDir];
        _resourceDownloadTasks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

#pragma -mark public method
-(void)downloadResource:(NSString *)url
        destinationPath:(NSString *)destinationPath
        progressHandler:(void (^)(float progress))progressHandler
      completionHandler:(void (^)(BOOL success, NSData *data, NSHTTPURLResponse *response))completionHandler
{
    if (!url || url.length == 0)
        return;
    [self downloadResourcB:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] destinationPath:destinationPath progressHandler:progressHandler completionHandler:completionHandler redirtctHandler:nil];
}

- (void)downloadResourcB:(NSURLRequest *)request destinationPath:(NSString *)destinationPath progressHandler:(void (^)(float))progressHandler completionHandler:(void (^)(BOOL, NSData *, NSHTTPURLResponse *))completionHandler redirtctHandler:(WQADownloadRedirtctHandler)redirtctHandler{
    WEAK_SELF_DECLARED
    NSString *url = request.URL.absoluteString;
    dispatch_async(resourceDownloadSerialQueue, ^{
        STRONG_SELF_BEGIN
        if (url.length == 0) {
            //[Log w:WQA_RES_DOWNLOADER format:@"downloadResource, but url is nil"];
            completionHandler(NO, nil, nil);
            return;
        }
        
        if ([strongSelf.resourceDownloadTasks objectForKey:url]) {
            WQADownloadItem* item = [strongSelf.resourceDownloadTasks objectForKey:url];
            [item addInvokeHandler:completionHandler progressHandler:progressHandler redirtctHandler:redirtctHandler];
            return;
        }
        
        WQADownloadItem* item = [[WQADownloadItem alloc] init];
        [item addInvokeHandler:completionHandler progressHandler:progressHandler redirtctHandler:redirtctHandler];
        item.desFilePath = destinationPath;
        item.tmpFilePath = [self tmpFilePathForUrl:url];
        NSData* tmpData = [NSData dataWithContentsOfFile:item.tmpFilePath];
        if(tmpData == nil) {
            item.bytesBuffer = [[NSMutableData alloc] init];
        }else {
            item.bytesBuffer = [NSMutableData dataWithData:tmpData];
        }
        item.lastTimeDownloadBytes = item.bytesBuffer.length;
        item.task = [self startDownload:[request mutableCopy] fromBytes:(int)item.bytesBuffer.length];
        [strongSelf.resourceDownloadTasks setObject:item forKey:url];
        [strongSelf.resourceDownloadTasks setObject:item forKey:item.task.currentRequest.URL.absoluteString];
        [self.updateReqDelegate updateReqMillis];
        [item.task resume];
        STRONG_SELF_END
    });
}

- (void)cancelDownloadUrl:(NSString*)url
{
    if (url.length == 0){
        return;
    }
    WEAK_SELF_DECLARED
    dispatch_sync(resourceDownloadSerialQueue, ^{
        STRONG_SELF_BEGIN
        WQADownloadItem* enity = [strongSelf.resourceDownloadTasks objectForKey:url];
        if (enity.bytesBuffer.length >0) {
            [enity.bytesBuffer writeToFile:enity.tmpFilePath atomically:YES];
        }
        if (enity) {
            [enity.task cancel];
        }
        [strongSelf.resourceDownloadTasks removeObjectForKey:url];
        STRONG_SELF_END
    });
}

#pragma -mark internal download task
- (NSURLSessionDataTask*)startDownload:(NSMutableURLRequest*)request fromBytes:(int)fromBytes
{
    if (fromBytes > 0) {
        [request setValue:[NSString stringWithFormat:@"bytes=%d-",fromBytes] forHTTPHeaderField:@"Range"];
    }
    __weak typeof(self) weakSelf = self;
    AFHTTPSessionManager *sessionManager = [self httpResourceDownloadSession];
    [sessionManager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf updateResponse:response forUrl:response.URL.absoluteString];
        }
        return NSURLSessionResponseAllow;
    }];
    
    [sessionManager setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf updateDataAlreadyRead:data forUrl:dataTask.response.URL.absoluteString];
        }
    }];
    //处理302重定向 将重定向转给wkwebview http下载不再处理重定向
    [sessionManager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest * _Nonnull(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request) {
        dispatch_sync(resourceDownloadSerialQueue, ^{
            STRONG_SELF_BEGIN
            NSString *originUrl = response.URL.absoluteString;
            WQADownloadItem* enity = [strongSelf.resourceDownloadTasks objectForKey:originUrl];
            if (enity) {
                [strongSelf.resourceDownloadTasks removeObjectForKey:originUrl];
                [[NSFileManager defaultManager] removeItemAtPath:enity.tmpFilePath error:nil];
                [enity invokeRedirtctHandlers:request response:response];
            }
            STRONG_SELF_END
        });
        return nil;
    }];
    
    NSURLSessionDataTask* task = [sessionManager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [sessionManager invalidateSessionCancelingTasks:YES resetSession:YES];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf reportDownloadResult:(NSHTTPURLResponse *)response error:error forUrl:response.URL.absoluteString];
        }
    }];
    return task;
}

#pragma -mark update download status
- (void)updateResponse:(NSURLResponse *)response forUrl:(NSString*)url
{
    WEAK_SELF_DECLARED
    dispatch_async(resourceDownloadSerialQueue, ^{
        STRONG_SELF_BEGIN
        //[Log d:WQA_RES_DOWNLOADER format:@"reveive response: %@",response];
        WQADownloadItem* enity = [strongSelf.resourceDownloadTasks objectForKey:url];
        if (enity) {
            enity.thisTimeDownloadExpectBytes = response.expectedContentLength;
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            NSDictionary* allHttpHeaders = [httpResponse allHeaderFields];
            NSString* bytesStr = [allHttpHeaders objectForKey:@"Accept-Ranges"];
            if (httpResponse.statusCode == 200 && ![@"bytes" isEqualToString:bytesStr]) {
                //[Log w:WQA_RES_DOWNLOADER format:@"download url:%@ not support Accept-Ranges!!",url];
                enity.lastTimeDownloadBytes = 0;
                enity.bytesBuffer = [[NSMutableData alloc] init];
                enity.response = response;
            }
        }
        STRONG_SELF_END
    });
}

- (void)updateDataAlreadyRead:(NSData*)data forUrl:(NSString*)url
{
    WEAK_SELF_DECLARED
    dispatch_async(resourceDownloadSerialQueue, ^{
        STRONG_SELF_BEGIN
        WQADownloadItem* enity = [strongSelf.resourceDownloadTasks objectForKey:url];
        if (enity) {
            [enity.bytesBuffer appendData:data];
            float progress = enity.bytesBuffer.length * 1.0f / (enity.lastTimeDownloadBytes + enity.thisTimeDownloadExpectBytes);
            [enity invokeProgressHandlers:progress];
        }
        STRONG_SELF_END
    });
}

- (void)reportDownloadResult:(NSHTTPURLResponse *)response error:(NSError*)error forUrl:(NSString*)url
{
    WEAK_SELF_DECLARED
    dispatch_async(resourceDownloadSerialQueue, ^{
        STRONG_SELF_BEGIN
        //[Log d:WQA_RES_DOWNLOADER format:@"download final response:%@, error:%@", response, error];
        WQADownloadItem* enity = [strongSelf.resourceDownloadTasks objectForKey:url];
        if (enity) {
            [strongSelf.resourceDownloadTasks removeObjectForKey:url];
            [enity.bytesBuffer writeToFile:enity.tmpFilePath atomically:YES];
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            if (httpResponse.statusCode == 416) {  // Range error, remove local temp file
                //[Log w:WQA_RES_DOWNLOADER format:@"range error, remove local temp file"];
                [[NSFileManager defaultManager] removeItemAtPath:enity.tmpFilePath error:nil];
            }
            if (error != nil && error.code != NSURLErrorCancelled) {
                //[Log e:WQA_RES_DOWNLOADER format:@"ResourceDownload error:%@",error];
                [enity invokeCompletionHandlers:NO data:enity.bytesBuffer response:response];
            }else {
                if (httpResponse.statusCode == 200 || httpResponse.statusCode == 206) {
                    [enity invokeCompletionHandlers:YES data:enity.bytesBuffer response:response];
                    if (enity.desFilePath) {
                        if ([[NSFileManager defaultManager] fileExistsAtPath:enity.desFilePath]) {
                            [[NSFileManager defaultManager] removeItemAtPath:enity.desFilePath error:nil];
                        }
                        WQAURLProtocolCacheData *protocolData = [[WQAURLProtocolCacheData alloc] init];
                        protocolData.data = enity.bytesBuffer;
                        protocolData.response = enity.response;
                        [NSKeyedArchiver archiveRootObject:protocolData toFile:enity.desFilePath];
                        [[NSFileManager defaultManager] removeItemAtPath:enity.tmpFilePath error:nil];
                    }
                    else {
                        [[NSFileManager defaultManager] removeItemAtPath:enity.tmpFilePath error:nil];
                    }
                }
                else {
                    [enity invokeCompletionHandlers:NO data:enity.bytesBuffer response:response];
                }
            }
        }
        STRONG_SELF_END
    });
}

#pragma -mark SessionManager
- (AFHTTPSessionManager *)httpResourceDownloadSession {
    AFHTTPSessionManager *httpResourceDownloadSession_;
    httpResourceDownloadSession_ = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:nil];
    httpResourceDownloadSession_.responseSerializer = [AFHTTPResponseSerializer serializer];
    httpResourceDownloadSession_.responseSerializer.acceptableContentTypes = nil;
    //[DNSInterceptor antiDnsSpoofing:httpResourceDownloadSession_ withHosts:nil];
    return httpResourceDownloadSession_;
}

#pragma -mark Utils
- (NSData*)tmpDataForUrl:(NSString*)url
{
    if (url.length == 0) {
        return nil;
    }
    NSString* tempFilePath = [self tmpFilePathForUrl:url];
    return [NSData dataWithContentsOfFile:tempFilePath];
}

- (NSString *)bgf_md5String:(NSData *)data {
    unsigned char result[16];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSString*)tmpFilePathForUrl:(NSString*)url
{
    return [_resourceTempFileDir stringByAppendingPathComponent:[self bgf_md5String:[url dataUsingEncoding:NSUTF8StringEncoding]]];
}

- (NSString *)tmpFileDir
{
    NSString* tmpDir = nil;
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if (dirs.count > 0) {
        NSString *baseDir = dirs[0];
        tmpDir = [baseDir stringByAppendingPathComponent:WQA_RES_DATA_DIR];
    }
    if (tmpDir.length > 0) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tmpDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return tmpDir;
}


@end
