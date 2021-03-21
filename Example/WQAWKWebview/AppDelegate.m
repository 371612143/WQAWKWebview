//
//  WQAAppDelegate.m
//  WQAWKWebview
//
//  Created by a371612143@qq.com on 03/21/2021.
//  Copyright (c) 2021 a371612143@qq.com. All rights reserved.
//

#import "AppDelegate.h"
#import <WQAWebEnvironment.h>
#import <WQAOfflineUtil.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    [WQAWebEnvironment sharedInstance];
    WQAEnvironmentInstance.webviewCacheLevel = 2;
    [WQAOfflineUtil switchOnOfflineCache:@""]; //配置需要预下载的资源列表
    WQAEnvironmentInstance.overWallSwitch = 0;
    WQAEnvironmentInstance.cacheTrustDomains = @[ @"doc.weixin.qq.com", @"ocmock.org",@"163.com"];
    [WQAEnvironmentInstance updateWebviewCountLimit:3];
    [[WQAResourceManager sharedInstance] init];
    WQAViewController *controller = [[WQAViewController alloc] init];
    self.mainViewController = controller;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    nav.navigationBar.translucent = NO;
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
