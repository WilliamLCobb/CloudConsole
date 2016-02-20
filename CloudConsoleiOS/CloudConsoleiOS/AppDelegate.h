//
//  AppDelegate.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  https://github.com/facebook/KVOController
//  https://github.com/vsouza/awesome-ios

#import <UIKit/UIKit.h>

#define kAppColor [UIColor colorWithRed:0 green:122/255.0 blue:1 alpha:1]

@class CCINetworkController;
@class CCIGame;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CCINetworkController *networkController;

+ (AppDelegate*)sharedInstance;
- (void)launchGame:(CCIGame *)game;
- (void)showError:(NSString *)error withTitle:(NSString *)title;
- (void)showWarning:(NSString *)error withTitle:(NSString *)title;

@end

