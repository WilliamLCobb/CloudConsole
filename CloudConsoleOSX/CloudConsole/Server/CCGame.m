//
//  CCGame.m
//  CloudConsole
//
//  Created by Will Cobb on 1/22/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCGame.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <libproc.h>

#import "CCPlugin.h"


@interface CCGame () {
    BOOL hasTable;
    BOOL hasSettings;
}

@end

@implementation CCGame

- (id)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        self.path = path;
        self.name = [[CCGame applicationNameForPath:path] stringByDeletingPathExtension];
        self.icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        self.icon.size = NSMakeSize(32, 32);
        self.running = NO;
                  //[[NSImage alloc] initWithContentsOfFile:path];
        hasTable = [CCPlugin pluginWithNameHasTable:self.name];
        hasSettings = [CCPlugin pluginWithNameHasSettings:self.name];
    }
    
    return self;
}

- (NSDictionary *)dataRepresentation
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    
    data[@"hasTable"] = [NSNumber numberWithBool:hasTable];
    data[@"hasSettings"] = [NSNumber numberWithBool:hasSettings];
    data[@"path"] = self.path;
    data[@"running"] = [NSNumber numberWithBool:self.running];
    
    if (self.icon) {
        NSData *pictureData = [CCGame pngDataForImage:self.icon];
        data[@"image"] = [pictureData base64EncodedStringWithOptions:0];
    }
    
    return data;
}

- (NSString *)applicationNameFromPid:(pid_t)pid {
    NSString *processPath = [CCGame processPathFromPid:pid];
    if (!processPath) {
        NSLog(@"Error: No path for process");
        return nil;
    }
    return [CCGame applicationNameForPath:processPath];
}

+(NSString *)applicationNameForPath:(NSString *)path
{
    for (NSString * component in path.pathComponents) {
        if ([component.pathExtension.lowercaseString isEqualToString:@"app"]) {
            return component.stringByDeletingPathExtension;
        }
    }
    return nil;
}

+(NSString *)processPathFromPid:(pid_t)apid {
    int ret;
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    ret = proc_pidpath (apid, pathbuf, sizeof(pathbuf));
    if ( ret <= 0 ) {
        printf("PID %d: proc_pidpath ();\n", apid);
        printf("    %s\n", strerror(errno));
        return nil;
    } else {
        printf("proc %d: %s\n", apid, pathbuf);
    }
    return [NSString stringWithUTF8String:pathbuf];
}

+(NSData *)pngDataForImage:(NSImage *)image {
    
    CGImageRef cgRef = [image CGImageForProposedRect:NULL
                                             context:nil
                                               hints:nil];
    NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
    [newRep setSize:[image size]];
    return [newRep representationUsingType:NSPNGFileType properties:nil];
}


+(NSArray <NSString *> *)defaultPaths
{
    return @[@"/Applications"];
}

+(NSArray <CCGame *> *)applicationsAtPaths:(NSArray *)searchPaths
{
    NSMutableArray *games = [NSMutableArray new];
    NSArray *validNames = [[NSUserDefaults standardUserDefaults] arrayForKey:@"validApplicationNames"];
    if (!validNames) {
        validNames = @[@"Dolphin.app", @"Citra.app", @"VLC.app"]; //Default games
        [[NSUserDefaults standardUserDefaults] setObject:validNames forKey:@"validApplicationNames"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    for (NSString *path in searchPaths) {
        [games addObjectsFromArray:[self applicationsAtPath:path validNames:validNames]];
    }
    return games;
}

+(NSArray <CCGame *> *)applicationsAtPath:(NSString *)path validNames:(NSArray *)validNames;
{
    
    NSError *error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    NSMutableArray *games = [NSMutableArray new];
    if (error) {
        NSLog(@"Error <applicationsAtPath:>: %@", error);
    }
    for (NSString *appName in directoryContents) {
        if ((!validNames || [validNames containsObject:appName]) && [appName.pathExtension.lowercaseString isEqualToString:@"app"]) {
            NSString *gamePath = [path stringByAppendingPathComponent:appName];
            [games addObject:[[CCGame alloc] initWithPath:gamePath]];
        }
    }
    return games;
}

+(NSArray <CCGame *> *)allApplicationsAtPaths:(NSArray *)searchPaths
{
    NSMutableArray *games = [NSMutableArray new];
    for (NSString *path in searchPaths) {
        [games addObjectsFromArray:[self applicationsAtPath:path validNames:nil]];
    }
    return games;
}
@end
