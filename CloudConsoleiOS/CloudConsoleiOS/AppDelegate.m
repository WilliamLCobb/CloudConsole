//
//  AppDelegate.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  https://github.com/romaonthego/REFrostedViewController
//  https://github.com/TransitApp/SVWebViewController
//  https://github.com/yukiasai/Gecco
//  http://cache1.asset-cache.net/gc/165073323-hardware-icons-white-gettyimages.jpg?v=1&c=IWSAsset&k=2&d=iLLR%2FeOet1oeMTS%2BjJBoqjTMwVQ8IBXq6GwF87dIk6Wth2qsG0%2F%2Be2FTdkpTaKtY
#import "AppDelegate.h"
#import "CCINetworkController.h"

#import <mach/mach.h>
#import <mach/mach_time.h>

#import "SCLAlertView.h"
#import "CCIStreamManager.h"
#import "CCIStreamViewController.h"
#import "CCIGame.h"

@interface AppDelegate () {
    mach_timebase_info_data_t _mach_timebase;
}
    
@end

@implementation AppDelegate

+ (AppDelegate*)sharedInstance
{
    return [[UIApplication sharedApplication] delegate];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    mach_timebase_info(&_mach_timebase);
    
    return YES;
}

- (void)launchGame:(CCIGame *)game
{
    CCIStreamManager *streamManager = [AppDelegate.sharedInstance.networkController startStreamWithGame:game];
    CCIStreamViewController *streamViewController = (CCIStreamViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CCIStreamViewController"];
    streamViewController.streamManager = streamManager;
    
    streamManager.outputDelegate = streamViewController;
    [[self topMostController] presentViewController:streamViewController animated:YES completion:nil];
}

- (void)showWarning:(NSString *)error withTitle:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^{
        SCLAlertView * alertView = [[SCLAlertView alloc] init];
        alertView.shouldDismissOnTapOutside = YES;
        [alertView showWarning:[self topMostController] title:title subTitle:error closeButtonTitle:@"Okay" duration:0.0];
    });
}

- (void)showError:(NSString *)error withTitle:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^{
        SCLAlertView * alertView = [[SCLAlertView alloc] init];
        alertView.shouldDismissOnTapOutside = YES;
        [alertView showError:[self topMostController] title:title subTitle:error closeButtonTitle:@"Okay" duration:0.0];
    });
}

- (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(double)mach_time_seconds
{
    double retval;
    
    uint64_t mach_now = mach_absolute_time();
    retval = (double)((mach_now * _mach_timebase.numer / _mach_timebase.denom))/NSEC_PER_SEC;
    return retval;
}

@end
