//
//  CCPluginManager.h
//  CloudConsole
//
//  Created by Will Cobb on 1/24/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface CCPlugin : NSObject

@property NSString *name;

- (id)initWithName:(NSString *)pluginName;

- (void)reload;
- (NSArray *)subGames;
- (NSRunningApplication *)launchGameWithPath:(NSString *)path;

+ (BOOL)pluginWithNameExists:(NSString *)pluginName;
+ (BOOL)pluginWithNameHasTable:(NSString *)pluginName;
+ (BOOL)pluginWithNameHasSettings:(NSString *)pluginName;

@end
