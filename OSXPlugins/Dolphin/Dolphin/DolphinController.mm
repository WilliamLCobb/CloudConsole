//
//  DolphinController.m
//  Dolphin
//
//  Created by Will Cobb on 1/24/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "DolphinController.h"

@interface DolphinController() {
    NSDictionary *dolphinSettings;
    NSDictionary *dolphinRoms;
}
@end

@implementation DolphinController

- (id)init
{
    if (self = [super init]) {
        [self reload];
    }
    return self;
}

- (NSRunningApplication *)launchGameWithPath:(NSString *)path
{
    // Opens the iso with Dolphin
    if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Dolphin"]) {
        NSLog(@"Error launching Dolphin");
        return nil;
    }
    
    // Loops through open apps looking for Dolphin
    // ToDo: this can fail if multiple instances of Dolphin are open.
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if ([app.localizedName isEqualToString:@"Dolphin"]) {
            return app;
        }
    }
    return nil;

}

- (void)reload
{
    dolphinSettings = [self settingsFromFile:[[self settingPath] stringByAppendingPathComponent:@"Config/Dolphin.ini"]];
}

- (NSArray *)subGames
{
    NSArray *paths = [self romPathsFromSettings:dolphinSettings];
    if (paths.count == 0) {
        NSLog(@"Error, no roms found");
        return [NSArray new];
    }
    NSMutableArray *roms = [NSMutableArray array];
    NSError *error;
    // Look through every path and build an array of roms
    // Currently roms can set:
    //   @"path" : The path send to launchGameWithPath:
    //   @"hasSettings" : indicates weather the device should show a settings icon for the application
    //   @"hasTable" : indicates weather the application will show a second table allowing the user to launch specific items
    //   @"name" : Displayed name for the rom
    //   @"image" : optional but recommened icon in PNG or JPEG format to be displayed to the user
    //              other formats may work but are not guarenteed to be supported
    for (NSString *path in paths) {
        NSArray * romPaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
        for (NSString *romPath in romPaths) {
            if ([[romPath.pathExtension lowercaseString] isEqualToString:@"iso"]) {
                //For each rom
                NSMutableDictionary *romDict = [NSMutableDictionary dictionary];
                NSString *fullPath = [path stringByAppendingPathComponent:romPath];
                romDict[@"path"] = fullPath;
                romDict[@"hasSettings"] = [NSNumber numberWithBool:NO];
                romDict[@"hasTable"] = [NSNumber numberWithBool:NO];
                romDict[@"name"] = [self nameForRomAtPath:fullPath];
                [roms addObject:romDict];
            }
        }
    }
    return roms;
}

- (NSString *)nameForRomAtPath:(NSString *)path
{
    // In the rom header, names are stores at 0x20 with a length of 0x3e0
    NSFileHandle *handle =[NSFileHandle fileHandleForReadingAtPath:path];
    [handle seekToFileOffset:0x20];
    NSData *gameNameData = [handle readDataOfLength:0x03e0];
    NSString *name = [[NSString alloc] initWithData:gameNameData encoding:NSASCIIStringEncoding];
    return [name substringToIndex:name.length-3];
}

- (NSString *)settingPath
{
    // Dolphin configuration usually lives in ~/Library/Application Support/Dolphin
    return [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/Dolphin"];
}

- (NSDictionary *)settingsFromFile:(NSString *)filePath
{
    // Reads file and returns a dictionairy of options and values
    NSError *error;
    NSString *fileData = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error getting file data: %@", [error localizedDescription]);
        return nil;
    }
    NSMutableDictionary *settings = [NSMutableDictionary new];
    NSArray *lines = [fileData componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        if ([line rangeOfString:@" = "].location != NSNotFound) {
            NSArray *keyValue = [line componentsSeparatedByString:@" = "];
            settings[keyValue[0]] = keyValue[1];
        }
    }
    return settings;
}

- (NSArray <NSString *> *)romPathsFromSettings:(NSDictionary *)settings
{
    //Reads through the settings file and finds all rows starting with "ISOPath"
    NSMutableArray *paths = [NSMutableArray new];
    for (NSString *key in [settings allKeys]) {
        if (key.length >= 7 && [[key substringToIndex:7] isEqualToString:@"ISOPath"]) {
            [paths addObject:[settings objectForKey:key]];
        }
    }
    return paths;
}

/* Reading Banner Test */

- (void)readEntryFromHandle:(NSFileHandle *)handle
{
    uint8_t type = *(uint8_t*)[handle readDataOfLength:0x1].bytes;
    NSLog(@"  Entry Type: %d", type);
    
    long fstOffset = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x3].bytes);
    //NSLog(@"  Entry Extension offset: %d", [[NSString alloc] initWithData:extData encoding:NSASCIIStringEncoding]);
    
    
    //uint32_t
}

- (void)dTest
{
    NSFileHandle *handle =[NSFileHandle fileHandleForReadingAtPath:@"/Users/willcobb/Dropbox/Roms/Dolphin/Super Mario Sunshine.iso"];
    [handle seekToFileOffset:0x424];
    long fstOffset = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    long fstSize = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    NSLog(@"Offset: %ld", fstOffset);
    NSLog(@"Size: %ld", fstSize);
    
    [handle seekToFileOffset:fstOffset];
    NSLog(@"Reading Root:");
    [self readEntryFromHandle:handle];
}

@end











