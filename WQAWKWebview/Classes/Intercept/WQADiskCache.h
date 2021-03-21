//
//  WQACacheManager.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/4.
//  Copyright © 2019 matthew. All rights reserved.
//

#import <Foundation/Foundation.h>

#define WQAAppletsCache         @"WQAAppletsCache"
#define WQAWebAppletsEntrance   @"index.html"
#define WQAConfigFileName       @"offlineConfig_reponse.json"

@class WQAAppletsItem;
NS_ASSUME_NONNULL_BEGIN

@interface WQADiskCache : NSObject
- (void)clearAllCache;
- (CGFloat)diskCacheSize;   //磁盘缓存大小kb
- (NSString *)getAppletsDirectory:(NSString *)appletsID;
- (void)removeApplets:(WQAAppletsItem *)item appletsID:(NSString *)appletsID;
- (NSString *)resourceDestPath:(NSURL *)resourceURL mainDocumentURL:(NSURL *)mainDocumentURL appletsID:(NSString *)appletsID;  //获取资源下载的存放地址
+ (NSString *)configFilePath;


@property (atomic, assign)NSInteger maxCacheCount;
@property (atomic, assign)NSTimeInterval maxCacheAge;
@property (atomic, strong, readonly) NSString *savePath;
@end

NS_ASSUME_NONNULL_END
