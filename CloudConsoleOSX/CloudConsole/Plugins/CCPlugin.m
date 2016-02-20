//
//  CCPluginManager.m
//  CloudConsole
//
//  Created by Will Cobb on 1/24/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCPlugin.h"
#import "CCGame.h"
#import "AppDelegate.h"
#define kHasTable @"HasTable"
#define kHasSettings @"HasSettings"

/*
 * This is the protocol plugins must follow
 */
@protocol CCPluginProtocol <NSObject>
/**
 * Signals for the plugin to reload settings and files.
 **/
- (void)reload;
- (NSArray *)subGames;
- (NSRunningApplication *)launchGameWithPath:(NSString *)path;

@end

@interface CCPlugin () {
    id <CCPluginProtocol> plugin;
}

@end

@implementation CCPlugin

- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = name;
        NSBundle *bundle;
        Class principalClass;
        NSString *pluginPath = [CCPlugin pathToPluginWithName:name];
        if (!pluginPath) { //Not in bundle, check app support
            NSLog(@"No plugin, using default");
            return self;
        }
        NSLog(@"Plugin Path: %@", pluginPath);
        bundle = [NSBundle bundleWithPath:pluginPath];
        principalClass = [bundle principalClass];
        plugin = [[principalClass alloc] init];
    }
    return self;
}

- (void)reload
{
    if (plugin && [plugin respondsToSelector:@selector(reload)]) {
        [plugin reload];
    }
}
- (NSArray *)subGames
{
    if (plugin && [plugin respondsToSelector:@selector(subGames)]) {
        return [plugin subGames];
    }
    return nil;
}
- (NSRunningApplication *)launchGameWithPath:(NSString *)path
{
    if (plugin && [plugin respondsToSelector:@selector(launchGameWithPath:)]) {
        return [plugin launchGameWithPath:path];
    } else {
        if (![[NSWorkspace sharedWorkspace] launchApplication:path]) {
            NSLog(@"Error launching Game");
            return nil;
        }
        // Loops through open apps looking for our application
        for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
            if ([app.localizedName isEqualToString:[CCGame applicationNameForPath:path]]) {
                return app;
            }
        }
        return nil;
    }
}

#pragma mark - Class Methods

+ (BOOL)pluginWithNameExists:(NSString *)pluginName
{
    return [CCPlugin pathToPluginWithName:pluginName] != nil;
}

+ (BOOL)pluginWithNameHasSettings:(NSString *)pluginName
{
    NSDictionary *pluginInfo = [CCPlugin dictionaryForPluginWithName:pluginName];
    if ([[pluginInfo objectForKey:kHasSettings] boolValue]) {
        return YES;
    }
    return NO;
}

+ (BOOL)pluginWithNameHasTable:(NSString *)pluginName
{
    NSDictionary *pluginInfo = [CCPlugin dictionaryForPluginWithName:pluginName];
    if ([[pluginInfo objectForKey:kHasTable] boolValue]) {
        return YES;
    }
    return NO;
}

+ (NSDictionary *)dictionaryForPluginWithName:(NSString *)pluginName
{
    NSString *pluginPath = [CCPlugin pathToPluginWithName:pluginName];
    if (!pluginPath)
        return nil;
    NSString *plistPath = [pluginPath stringByAppendingPathComponent:@"Contents/info.plist"];
    return [NSDictionary dictionaryWithContentsOfFile:plistPath];
}

+ (NSString *)pathToPluginWithName:(NSString *)pluginName
{
    NSString *pluginPath = [[NSBundle mainBundle] pathForResource:pluginName ofType:@"ccop"];
    if (!pluginPath) { //Not in bundle, check app support
        pluginPath = [NSString stringWithFormat:@"%@/Plugins/%@.ccop", [AppDelegate supportFolder], pluginName];
        NSLog(@"Looking in for plugin in: %@", pluginPath);
        if ([[NSFileManager defaultManager] fileExistsAtPath:pluginPath]) {
            NSLog(@"Found in alternate path");
        } else { //Did not find a plugin
            NSLog(@"No plugin, using default");
            return nil;
        }
    }
    return pluginPath;
}

@end
