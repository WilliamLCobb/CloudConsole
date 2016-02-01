//
//  AppDelegate.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CCINetworkController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

+ (AppDelegate*)sharedInstance;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) CCINetworkController *networkController;

@end

