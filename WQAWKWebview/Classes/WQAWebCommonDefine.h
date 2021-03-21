//
//  CommonDefine.h
//  CommonLib
//
//  Created by matthew on 2019/3/20.
//  Copyright © 2019年 matthew. All rights reserved.
//

#ifndef WQAWebCommonDefine_h
#define WQAWebCommonDefine_h

#define WQAWeb_BLANK_URL    @"about:blank"
//业务中的相关单例
#define USER_DEFAULTS                   [NSUserDefaults standardUserDefaults]
#define NOTIFICATION_CENTER             [NSNotificationCenter defaultCenter]

#define WEAK_SELF_DECLARED  typeof(&*self) __weak weakSelf = self;
#define STRONG_SELF_BEGIN   typeof(&*weakSelf) strongSelf = weakSelf; \
                            if (strongSelf) {
#define STRONG_SELF_END     }

#define DISPATCH_TIME_IN_SEC(secs)      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(secs * NSEC_PER_SEC))


#define SINGLE_DECL(_CLS_TYPE)  + (instancetype)sharedInstance;

#define SINGLETON_IMP(_CLS_TYPE) \
+ (instancetype)sharedInstance {\
    static _CLS_TYPE *instance = nil;\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        instance = [[super allocWithZone:nil] init];\
    });\
    return instance;\
}\
+ (id)allocWithZone:(struct _NSZone *)zone {return [self sharedInstance];}\
-(id)copyWithZone:(NSZone *)zone{return self;}\
-(id)mutableCopyWithZone:(NSZone *)zone{return self;}\

#define likely(x) __builtin_expect(!!(x), 1) //x很可能为真,这样编译出的指令是预先读取为真分支的数据和指令寄存
#define unlikely(x) __builtin_expect(!!(x), 0) //x很可能为假 这样编译出的指令是预先读取为假分支的数据和指令寄存

//打点日志相关宏定义
#define kNotificationWQAWebStageChanged @"kNotificationWQAWebStageChanged"

#define WQAEnvironmentInstance ([WQAWebEnvironment sharedInstance])

//Hive上报
#define WQAWebReport(__eventId__, __eventInfo__) [[WQAWebEnvironment sharedInstance] WQAReport:__eventId__ event:__eventInfo__];
//页面加载上报
#define WQAStatisticsEventWebViewLoad       @"05304013"
//API调用错误上报
#define WQAStatisticsEventJSAPICallError    @"050101120"
//离线化节省流量大小
#define WQAEventOfflineCache                @"05304021"
//离线化配置文件下载失败
#define WQAEventDownloadConfig              @"05304022"

#endif /* WQAWebCommonDefine_h */
