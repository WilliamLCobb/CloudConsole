//
//  AppDelegate.h
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.4
//  Kulo9073

#import <Cocoa/Cocoa.h>
#import "AutoUpdate/AUUpdater.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, AUUpdaterDelegate>

@property (strong) id activity;
@property (strong, nonatomic) NSStatusItem *statusItem;


@end

