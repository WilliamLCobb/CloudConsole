//
//  CCPluginManager.h
//  CloudConsole
//
//  Created by Will Cobb on 1/24/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
@protocol CCPluginProtocol <NSObject>
/** 
 * Signals for the plugin to reload settings and files.
**/
- (void)reload;
- (NSArray *)subGames;
- (NSRunningApplication *)launchGameWithPath:(NSString *)path;

@end

@interface CCPlugin : NSObject

@property id <CCPluginProtocol> plugin;
@property NSString *name;

- (id)initWithName:(NSString *)pluginName;

+ (BOOL)pluginWithNameExists:(NSString *)pluginName;
+ (BOOL)pluginWithNameHasTable:(NSString *)pluginName;
+ (BOOL)pluginWithNameHasSettings:(NSString *)pluginName;

@end
