//
//  WQAResourceManager.h
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/4.
//  Copyright © 2019 matthew. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WQADiskCache.h>
#import <ObjcHelpFunc.h>
#import <WQAAppletsConfig.h>
#import "WQAResourceDownloader.h"

typedef void(^downloadSucessedBlock)(NSString *localPath, int errorCode);
typedef id(^NervDownloadBlock)(NSString *url, NSString *path, downloadSucessedBlock completion);
typedef void(^NervCancelDownBlock)(id nervTask);

@interface WQAResourceManager : NSObject

typedef void(^LBSDownloadSucessedBlock)(NSString *body, NSHTTPURLResponse *response, int errorCode);

SINGLE_DECL(WQAResourceManager)
//根据appid 下载资源
- (void)downloadAppletsResourece:(NSURLRequest *)requset
                 destinationPath:(NSString *)destinationPath
               completionHandler:(WQADownloadCompletionHandler)completionHandler
                 redirtctHandler:(WQADownloadRedirtctHandler)redirtctHandler;

- (void)LBSDownloadResource:(NSURLRequest *)request params:(NSDictionary *)params completion:(LBSDownloadSucessedBlock)completion;

- (void)initNervDownloadBlock:(NervDownloadBlock)nervDownloadBlock nervCancelBlock:(NervCancelDownBlock)nervCancelBlock;

- (void)NervDownloadResource:(NSString *)url path:(NSString *)path completion:(downloadSucessedBlock)completion;

- (void)cancelDownLoad:(NSString *)url;

//清除所有小程序配置和离线文件
- (void)clearAllCache;
- (CGFloat)diskCacheSize;   //磁盘缓存大小kb
- (NSString *)resourceDestPath:(NSURL *)resourceURL mainDocumentURL:(NSURL *)mainDocumentURL appletsID:(NSString *)appletsID;

@property (atomic, strong, readonly) WQAAppletsConfig *appletsConfig;
@property (nonatomic, strong)NSString *appletsConfigUrl;
@end


