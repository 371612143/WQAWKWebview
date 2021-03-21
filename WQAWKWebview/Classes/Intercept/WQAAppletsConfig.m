//
//  WQAAppletsConfig.m
//  WQAWebviewComponent
//
//  Created by matthew on 2019/6/12.
//

#import "WQAAppletsConfig.h"
#import "WQADiskCache.h"
#import "WQAOfflineUtil.h"

@interface WQAAppletsConfig()
@property (nonatomic, strong)NSDictionary *configData;
@end

@implementation WQAAppletsConfig

- (instancetype)initWithjsonData:(NSData *)jsonData {
    if (self = [super init]) {
        _appletsInfoList = [NSMutableDictionary new];
        if (jsonData) {
            NSError *error = nil;
            id configDict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
            self.configData = configDict;
        }
        else {
            self.configData = [NSDictionary new];
        }
    }
    return self;
}

+ (instancetype)configWithFile:(NSString *)path {
    WQAURLProtocolCacheData *diskConfig = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    WQAAppletsConfig *config = [[self alloc] initWithjsonData:diskConfig.data];
    return config;
}

- (WQAAppletsItem *)getItemConfig:(NSString *)appId {
    if (!appId) {
        return nil;
    }
    return _appletsInfoList[appId];
}

- (WQAAppletsItem *)getItemConfigWithURL:(NSURL *)url {
    if (url.absoluteString.length == 0) {
        return nil;
    }
    NSArray<NSString *> *pathComponents = url.pathComponents;
     if (pathComponents.count < 2)
         return nil;
    NSString *appId = pathComponents[pathComponents.count - 2];
    return [self getItemConfig:appId];

}

- (void)setConfigData:(NSDictionary *)configDict {
    if (![configDict isKindOfClass:[NSDictionary class]] || ![configDict[@"appletsInfoTable"] isKindOfClass:[NSDictionary class]]) {
        _configData = @{};
        return;
    }
    _configData = configDict;
    NSDictionary *appletsInfoTable = _configData[@"appletsInfoTable"];
    for (id key in appletsInfoTable.allKeys) {
        if ([appletsInfoTable[key] isKindOfClass:[NSDictionary class]]) {
            _appletsInfoList[key] = [[WQAAppletsItem alloc] initWithConfig:appletsInfoTable[key]];
            _appletsInfoList[key].appletsID = key;
        }
    }
}

- (NSString *)md5 {
    return _configData[@"md5"];
}

- (NSString *)appName {
    return _configData[@"appName"];
}

- (NSString *)version {
    return _configData[@"version"];
}

- (NSString *)lastModify {
    return _configData[@"lastModify"];
}
@end
