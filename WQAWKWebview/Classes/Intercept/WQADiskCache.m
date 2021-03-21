//
//  WQACacheManager.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/4.
//  Copyright © 2019 matthew. All rights reserved.
//

#import "WQADiskCache.h"
#import <WQAAppletsConfig.h>
#import "WQAOfflineUtil.h"
#import <CommonCrypto/CommonDigest.h>

@interface WQADiskCache()
@property (atomic, strong) NSString *savePath;
@property (nonatomic, strong) NSFileManager *WQAFileManger;

@property (nonatomic, strong) dispatch_queue_t  asyncQueue;
@property (nonatomic, strong) dispatch_semaphore_t sempahore;

@end

@implementation WQADiskCache

- (instancetype)init {
    if (self = [super init]) {
        _WQAFileManger = [NSFileManager new];
        _sempahore = dispatch_semaphore_create(1);
        _asyncQueue = dispatch_queue_create("com.WQAdiskcache.asyncqueue", DISPATCH_QUEUE_SERIAL);
        _savePath = [WQADiskCache createDirectoryIfNotExist];
        _maxCacheCount = 100*1024*1024;  //60M
        _maxCacheAge = 30*24*60*60;      //30 days
        //配置文件版本更新 需要清除以前缓存
        if (![_WQAFileManger fileExistsAtPath:[WQADiskCache configFilePath]]) {
            [self clearAllCache];
        }
        else {
            [NOTIFICATION_CENTER addObserver:self
                                    selector:@selector(applicationDidIdle:)
                                        name:UIApplicationDidEnterBackgroundNotification
                                      object:nil];
            
            [NOTIFICATION_CENTER addObserver:self
                                    selector:@selector(applicationDidIdle:)
                                        name:UIApplicationWillTerminateNotification
                                      object:nil];
        }
    }
    return self;
}

- (void)dealloc {
    [NOTIFICATION_CENTER removeObserver:UIApplicationDidEnterBackgroundNotification];
    [NOTIFICATION_CENTER removeObserver:UIApplicationWillTerminateNotification];
}

- (NSString *)getAppletsDirectory:(NSString *)appletsID {
    return self.savePath;
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

- (NSString *)resourceDestPath:(NSURL *)resourceURL mainDocumentURL:(NSURL *)mainDocumentURL appletsID:(NSString *)appletsID {
    resourceURL = [WQAOfflineUtil urlByDeletingParameters:resourceURL];
    if (!resourceURL) {
        return nil;
    }
    
    NSString *filePath = [self getAppletsDirectory:appletsID];
    NSString *pathExtension = resourceURL.pathExtension;
    if ([resourceURL.absoluteString isEqualToString:mainDocumentURL.absoluteString]) {
        pathExtension = @"html";
    }
    filePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", [self bgf_md5String:[resourceURL.absoluteString dataUsingEncoding:NSUTF8StringEncoding]], pathExtension]];
    return filePath;
}

//缓存清理相关逻辑LRU
- (void)applicationDidIdle:(NSNotification *)notify {
    WEAK_SELF_DECLARED
    dispatch_async(_asyncQueue, ^{
        STRONG_SELF_BEGIN
        [strongSelf lock];
        [strongSelf trimDiskToSizeByDate:strongSelf.maxCacheAge];
        [strongSelf unLock];
        STRONG_SELF_END
    });
}

- (void)clearAllCache {
    WEAK_SELF_DECLARED
    dispatch_async(_asyncQueue, ^{
        STRONG_SELF_BEGIN
        NSError *error = nil;
        [strongSelf lock];
        [strongSelf.WQAFileManger removeItemAtPath:strongSelf.savePath error:&error];
        if (!error) {
            strongSelf.savePath = [WQADiskCache createDirectoryIfNotExist];
        }
        [strongSelf unLock];
        STRONG_SELF_END
    });
}

- (CGFloat)diskCacheSize {
    __block CGFloat cacheSize = 0.0f;
    WEAK_SELF_DECLARED
    dispatch_sync(_asyncQueue, ^{
        STRONG_SELF_BEGIN
        [strongSelf lock];            
        NSURL *diskCacheURL = [NSURL fileURLWithPath:strongSelf.savePath isDirectory:YES];
        NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, NSURLTotalFileAllocatedSizeKey];
        
        NSDirectoryEnumerator *fileEnumerator = [strongSelf.WQAFileManger enumeratorAtURL:diskCacheURL
                                                         includingPropertiesForKeys:resourceKeys
                                                                            options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                       errorHandler:NULL];
        for (NSURL *fileURL in fileEnumerator) {
            NSError *error;
            NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
            if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
            cacheSize += totalAllocatedSize.floatValue;
        }
        [strongSelf unLock];
        STRONG_SELF_END
    });
    return cacheSize / 1024.0f;
}

- (void)removeApplets:(WQAAppletsItem *)item appletsID:(NSString *)appletsID{
    WEAK_SELF_DECLARED
    dispatch_async(_asyncQueue, ^{
        STRONG_SELF_BEGIN
        for (NSString *url in item.entranceList) {
            if (url.length == 0)
                continue;
            NSString *filePath = [strongSelf resourceDestPath:[NSURL URLWithString:url] mainDocumentURL:[NSURL URLWithString:url]  appletsID:appletsID];
            [strongSelf.WQAFileManger removeItemAtPath:filePath error:nil];
        }
        STRONG_SELF_END
    });
}

- (void)trimDiskToSizeByDate:(NSUInteger)trimByteCount
{
    if (!self.savePath) {
        logWebInfo(@"trimDiskToSizeByDate save path nil!");
        return;
    }
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.savePath isDirectory:YES];
    NSArray<NSString *> *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentAccessDateKey, NSURLTotalFileAllocatedSizeKey];
    
    NSDirectoryEnumerator *fileEnumerator = [self.WQAFileManger enumeratorAtURL:diskCacheURL
                                                     includingPropertiesForKeys:resourceKeys
                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                   errorHandler:NULL];
    
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
    NSMutableDictionary<NSURL *, NSDictionary<NSString *, id> *> *cacheFiles = [NSMutableDictionary dictionary];
    NSUInteger currentCacheSize = 0;
    
    NSMutableArray<NSURL *> *urlsToDelete = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileEnumerator) {
        NSError *error;
        NSDictionary<NSString *, id> *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:&error];
        if (error || !resourceValues || [resourceValues[NSURLIsDirectoryKey] boolValue]) {
            continue;
        }
        
        NSDate *modifiedDate = resourceValues[NSURLContentAccessDateKey];
        if (expirationDate && [[modifiedDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [urlsToDelete addObject:fileURL];
            continue;
        }
        
        NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
        currentCacheSize += totalAllocatedSize.unsignedIntegerValue;
        cacheFiles[fileURL] = resourceValues;
    }
    
    for (NSURL *fileURL in urlsToDelete) {
        [self.WQAFileManger removeItemAtURL:fileURL error:nil];
    }

    NSUInteger maxDiskSize = self.maxCacheCount;
    if (maxDiskSize > 0 && currentCacheSize > maxDiskSize) {
        const NSUInteger desiredCacheSize = maxDiskSize / 2;
        NSArray<NSURL *> *sortedFiles = [cacheFiles keysSortedByValueWithOptions:NSSortConcurrent
                                                                 usingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                                     return [obj1[NSURLContentAccessDateKey] compare:obj2[NSURLContentAccessDateKey]];
                                                                 }];
        
        for (NSURL *fileURL in sortedFiles) {
            if ([self.WQAFileManger removeItemAtURL:fileURL error:nil]) {
                NSDictionary<NSString *, id> *resourceValues = cacheFiles[fileURL];
                NSNumber *totalAllocatedSize = resourceValues[NSURLTotalFileAllocatedSizeKey];
                currentCacheSize -= totalAllocatedSize.unsignedIntegerValue;
                if (currentCacheSize < desiredCacheSize) {
                    break;
                }
            }
        }
    }
}

#pragma--mark disk path
+ (NSString *)createDirectoryIfNotExist {
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [documentDir stringByAppendingPathComponent:WQAAppletsCache];
    BOOL isDirectiory = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectiory]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            return nil;
        }
    }
    return path;
}

+ (NSString *)configFilePath {
    return [[self createDirectoryIfNotExist] stringByAppendingPathComponent:WQAConfigFileName];
}


#pragma mark -- lock
- (void)lock {
    dispatch_semaphore_wait(self.sempahore, DISPATCH_TIME_FOREVER);
}

- (void)unLock {
    dispatch_semaphore_signal(self.sempahore);
}

@end
