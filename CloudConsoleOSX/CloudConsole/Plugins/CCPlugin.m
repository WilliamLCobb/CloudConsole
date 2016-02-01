//
//  CCPluginManager.m
//  CloudConsole
//
//  Created by Will Cobb on 1/24/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCPlugin.h"

#define kHasTable @"HasTable"
#define kHasSettings @"HasSettings"

@interface CCPlugin () {
}

@end

@implementation CCPlugin

- (id)initWithDefaultPlugin
{
    return [super init];
}

- (id)initWithName:(NSString *)name
{
    if (self = [super init]) {
        _name = name;
        NSBundle *bundle;
        Class principalClass;
        NSString *pluginPath =[[NSBundle mainBundle] pathForResource:name ofType:@"ccop"];
        NSLog(@"Plugin Path%@", pluginPath);
        bundle = [NSBundle bundleWithPath:pluginPath];
        principalClass = [bundle principalClass];
        self.plugin = [[principalClass alloc] init];
    }
    return self;
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
    return [[NSBundle mainBundle] pathForResource:pluginName ofType:@"ccop"];
}

@end
