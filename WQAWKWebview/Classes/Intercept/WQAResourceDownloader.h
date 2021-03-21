//
//  AFHttpResourceDownloader.h
//  BSConnection
//
//  Created by caochao peng on 2018/4/20.
//

#import <Foundation/Foundation.h>

@protocol UpdateReqDelegate<NSObject>
-(void)updateReqMillis;
@end

typedef void (^WQADownloadProgressHandler)(float);
typedef void (^WQADownloadCompletionHandler)(BOOL, NSData *, NSHTTPURLResponse *);
typedef void (^WQADownloadRedirtctHandler)(NSURLRequest *request, NSURLResponse *response);

@interface WQAURLProtocolCacheData : NSObject<NSCoding>
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@end


@interface WQAResourceDownloader : NSObject

@property (nonatomic,strong) id<UpdateReqDelegate> updateReqDelegate;

- (void)downloadResource:(NSString*)url
         destinationPath:(NSString*)destinationPath
         progressHandler:(void(^)(float progress))progressHandler
       completionHandler:(void (^)(BOOL success, NSData *data, NSHTTPURLResponse *response))completionHandler;

- (void)downloadResourcB:(NSURLRequest*)request
         destinationPath:(NSString*)destinationPath
         progressHandler:(void(^)(float progress))progressHandler
       completionHandler:(void (^)(BOOL success, NSData *data, NSHTTPURLResponse *response))completionHandler
         redirtctHandler:(void(^)(NSURLRequest *request, NSURLResponse *response))redirtctHandler;
- (void)cancelDownloadUrl:(NSString*)url;


@end
