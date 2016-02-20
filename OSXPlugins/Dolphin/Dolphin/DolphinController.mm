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
    [self updateSettings];
    dolphinSettings = [self settingsFromFile:[[self settingsPath] stringByAppendingPathComponent:@"Config/Dolphin.ini"]];
}

- (void)updateSettings
{
    // Dolphin
    NSString *dolphinSettingsPath = [[self settingsPath] stringByAppendingPathComponent:@"Config/Dolphin.ini"];
    NSError *error;
    NSString *fileData = [[NSString alloc] initWithContentsOfFile:dolphinSettingsPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error getting file data: %@", [error localizedDescription]);
        return;
    }
    
    fileData = [self changeSetting:@"Fullscreen" to:@"False" forFileData:fileData];
    fileData = [self changeSetting:@"ConfirmStop" to:@"False" forFileData:fileData];
    fileData = [self changeSetting:@"BackgroundInput" to:@"True" forFileData:fileData];
    [fileData writeToFile:dolphinSettingsPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error writing: %@", [error localizedDescription]);
        return;
    }
    
    // Game pad
    NSString *gcpadSettingsPath = [[self settingsPath] stringByAppendingPathComponent:@"Config/GCPadNew.ini"];
    fileData = @"[GCPad1]\nDevice = Input/0/Cloud Console Gamecube Controller\nButtons/A = `Button 1`\nButtons/B = `Button 2`\nButtons/X = `Button 3`\nButtons/Y = `Button 4`\nButtons/Z = `Button 5`\nButtons/Start = `Button 8`\nMain Stick/Up = `Axis Y+`\nMain Stick/Down = `Axis Y-`\nMain Stick/Left = `Axis X-`\nMain Stick/Right = `Axis X+`\nMain Stick/Modifier/Range = 50.000000000000000\nC-Stick/Up = `Axis Rx+`\nC-Stick/Down = `Axis Rx-`\nC-Stick/Left = `Axis Z-`\nC-Stick/Right = `Axis Z+`\nC-Stick/Modifier = Left Control\nC-Stick/Modifier/Range = 50.000000000000000\nTriggers/L = `Button 7`\nTriggers/R = `Button 6`\nTriggers/L-Analog = `Button 7`\nTriggers/R-Analog = `Button 6`\nD-Pad/Up = `Button 9`\nD-Pad/Down = `Button 10`\nD-Pad/Left = `Button 11`\nD-Pad/Right = `Button 12`";
    [fileData writeToFile:gcpadSettingsPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error writing pad: %@", [error localizedDescription]);
        return;
    }
}

- (NSString *)changeSetting:(NSString *)setting to:(NSString *)value forFileData:(NSString *)fileData
{
    NSString *replacementString = [NSString stringWithFormat:@"%@ = %@\n", setting, value];
    
    NSError *error;
    NSString *pattern = [NSString stringWithFormat:@"%@ = .*\n", setting];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if (error) {
        NSLog(@"Regex Error: %@", error);
        return fileData;
    }
    NSString *modifiedFileData = [regex stringByReplacingMatchesInString:fileData options:0 range:NSMakeRange(0, [fileData length]) withTemplate:replacementString];
    
    return modifiedFileData;
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
                //Read banner
                NSFileHandle *handle =[NSFileHandle fileHandleForReadingAtPath:fullPath];
                uint32_t bannerOffset = [self findBannerOffsetFromHandle:handle];
                [handle seekToFileOffset:bannerOffset];
                romDict[@"name"] = [self nameFromBannerWithHandle:handle];
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

- (NSString *)settingsPath
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

/* Reading Banner file */

- (uint32_t)readRootFromHandle:(NSFileHandle *)handle
{
    uint8_t type = *(uint8_t*)[handle readDataOfLength:0x1].bytes;
    
    uint32_t stringOffset = *(uint32_t*)[handle readDataOfLength:0x3].bytes;
    NSLog(@"Entry Type: %d", type);
    NSLog(@"String Table Offset: %d", stringOffset);
    
    uint32_t fileOffset = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    NSLog(@"Root Offset: %u", fileOffset);
    uint32_t length = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    NSLog(@"num entries: %u", length);
    return length;
}

- (uint32_t)findBNRFromHandle:(NSFileHandle *)handle stringTableOffset:(uint32_t)tableOffset
{
    // Simply reads the fst format looking for opening.bnr
    uint8_t type = *(uint8_t*)[handle readDataOfLength:0x1].bytes;
    uint32_t stringOffset = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x3].bytes);
    stringOffset >>= 8;
    
    uint32_t fileOffset = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    uint32_t length = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    
    if (type == 0) {
        long long currentOffset = handle.offsetInFile;
        [handle seekToFileOffset:tableOffset + stringOffset];
        NSData *textData = [handle readDataOfLength:11];
        NSString *text = [[NSString alloc] initWithData:textData encoding:NSASCIIStringEncoding];
        if ([text isEqualToString:@"opening.bnr"]) {
            return fileOffset;
        }
        [handle seekToFileOffset:currentOffset];
    }
    return 0;
}

- (uint32_t)findBannerOffsetFromHandle:(NSFileHandle *)handle
{
    
    [handle seekToFileOffset:0x424];
    uint32_t fstOffset = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    long fstSize = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    NSLog(@"Offset: %u", fstOffset);
    NSLog(@"Size: %ld", fstSize);
    
    [handle seekToFileOffset:fstOffset];
    uint32_t numberOfEntries = [self readRootFromHandle:handle];
    NSLog(@"---Begin Reading %u entries---", numberOfEntries);
    uint32_t BNROffset = 0;
    for (int i = 0; i < numberOfEntries; i++) {
        BNROffset = [self findBNRFromHandle:handle stringTableOffset:fstOffset + numberOfEntries * 12];
        if (BNROffset != 0) {
            break;
        }
    }
    return BNROffset;
}

- (NSString *)nameFromBannerWithHandle:(NSFileHandle *)handle
{
    uint32_t magic = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    NSLog(@"m %u", magic);
    [handle seekToFileOffset:handle.offsetInFile + 0x185C];
    return [[NSString alloc] initWithData:[handle readDataOfLength:0x40] encoding:NSASCIIStringEncoding];
}

//96 x 32

- (NSData *)imageFromBannerWithHandle:(NSFileHandle *)handle
{
    uint32_t magic = CFSwapInt32BigToHost(*(uint32_t*)[handle readDataOfLength:0x4].bytes);
    NSLog(@"m %u", magic);
    [handle seekToFileOffset:handle.offsetInFile + 0x1C];
    NSData *imageData = [handle readDataOfLength:0x1800];
    return nil;
}

@end











