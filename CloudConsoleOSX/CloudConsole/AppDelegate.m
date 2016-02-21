//
//  AppDelegate.m
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  Kext https://developer.apple.com/contact/kext/

#import "AppDelegate.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import "CCOServer.h"
#import "NSImage+Transform.h"
#import <Sparkle/Sparkle.h>

@interface AppDelegate () <SUUpdaterDelegate> {
    NSTimer     *ipUpdateTimer;
    NSMenuItem  *ipItem;
    NSArray     *shakeImages;
    SUUpdater   *updater;
}
    
@end

@implementation AppDelegate

+ (AppDelegate*)sharedInstance
{
    return [[NSApplication sharedApplication] delegate];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    /*  Auto Update  */
    //com.WilliamCobb.CloudConsole
    
    updater = [SUUpdater updaterForBundle:[NSBundle bundleForClass:[self class]]];
    updater.delegate = self;
    updater.automaticallyChecksForUpdates = YES;
    updater.automaticallyDownloadsUpdates = YES;
    [updater checkForUpdatesInBackground];
    [updater resetUpdateCycle];
    
    [[CCOServer sharedInstance] start];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:25.0];
    self.statusItem.image = [NSImage imageNamed:@"menuIconTemplate"];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Cloud Console"];
    [menu addItemWithTitle:@"Cloud Console: Running" action:@selector(nothing) keyEquivalent:@""];
    
    NSString *IP = [[CCOServer sharedInstance] currentIP];
    ipItem = [menu addItemWithTitle:[NSString stringWithFormat:@"IP: %@", IP] action:@selector(nothing) keyEquivalent:@""];
    [menu insertItem:[NSMenuItem separatorItem] atIndex:1];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [menu addItemWithTitle:[NSString stringWithFormat:@"Version: %@", version]
                    action:@selector(nothing)
             keyEquivalent:@""];
    [menu addItemWithTitle:@"Quit" action:@selector(quitApplication) keyEquivalent:@"Q"];
    self.statusItem.menu = menu;
    ipUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateIp) userInfo:nil repeats:YES];
    
    //Start at startup
    if (![self isLaunchAtStartup]) {
        [self toggleLaunchAtStartup];
    }
    
    //Enter background mode
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityBackground reason:@"Backgrounding"];
    }
}


- (void)preventSleep
{
    //Prevents app nap
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        [[NSProcessInfo processInfo] endActivity:self.activity]; //End Background
        self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated reason:@"Streaming"];
    }
}

- (void)allowSleep
{
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(endActivity:)]) {
        [[NSProcessInfo processInfo] endActivity:self.activity];
        self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityBackground reason:@"Backgrounding"];
    }
}
     
- (void)nothing{}

- (void) updateIp
{
    NSString *IP = [[CCOServer sharedInstance] currentIP];
    ipItem.title = [NSString stringWithFormat:@"IP: %@", IP];
}

- (void)quitApplication
{
    [NSApp terminate:self];
}

#pragma mark - Update Delegate

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)item
{
    NSLog(@"Found update");
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)updater
{
    NSLog(@"Did not find update");
}

- (NSString *)feedURLStringForUpdater:(SUUpdater *)updater
{
    NSLog(@"Asked for URL");
    return @"10.0.1.16";
}

#pragma mark Launch at Startup

//http://stackoverflow.com/questions/608963/register-as-login-item-with-cocoa/
- (BOOL)isLaunchAtStartup {
    LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
    BOOL isInList = itemRef != nil;
    if (itemRef != nil) CFRelease(itemRef);
    
    return isInList;
}

- (void)toggleLaunchAtStartup {
    BOOL shouldBeToggled = ![self isLaunchAtStartup];
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return;
    if (shouldBeToggled) {
        // Add the app to the LoginItems list.
        CFURLRef appUrl = (__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
        LSSharedFileListItemRef itemRef = LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, appUrl, NULL, NULL);
        if (itemRef) CFRelease(itemRef);
    }
    else {
        // Remove the app from the LoginItems list.
        LSSharedFileListItemRef itemRef = [self itemRefInLoginItems];
        LSSharedFileListItemRemove(loginItemsRef,itemRef);
        if (itemRef != nil) CFRelease(itemRef);
    }
    CFRelease(loginItemsRef);
}

- (LSSharedFileListItemRef)itemRefInLoginItems {
    LSSharedFileListItemRef res = nil;
    
    // Get the app's URL.
    NSURL *bundleURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    // Get the LoginItems list.
    LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsRef == nil) return nil;
    // Iterate over the LoginItems.
    NSArray *loginItems = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, nil);
    for (id item in loginItems) {
        LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)(item);
        CFURLRef itemURLRef;
        if (LSSharedFileListItemResolve(itemRef, 0, &itemURLRef, NULL) == noErr) {
            // Again, use toll-free bridging.
            NSURL *itemURL = (__bridge NSURL *)itemURLRef;
            if ([itemURL isEqual:bundleURL]) {
                res = itemRef;
                break;
            }
        }
    }
    if (res != nil) CFRetain(res);
    CFRelease(loginItemsRef);
    CFRelease((__bridge CFTypeRef)(loginItems));
    
    return res;
}

#pragma mark - Shake

- (void)shake
{
    if (!shakeImages) {
        NSImage *baseImage = [NSImage imageNamed:@"menuIconTemplate"];
        shakeImages = @[[baseImage imageRotatedByDegrees:-8],
                        [baseImage imageRotatedByDegrees:-16],
                        [baseImage imageRotatedByDegrees:-8],
                        baseImage,
                        [baseImage imageRotatedByDegrees:8],
                        [baseImage imageRotatedByDegrees:16],
                        [baseImage imageRotatedByDegrees:8],
                        baseImage];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (int i = 0; i < 4; i++) {
            for (NSImage *image in shakeImages) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusItem.image = image;
                });
                [NSThread sleepForTimeInterval:0.013];
            }
        }
    });
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    self.statusItem.menu = nil;
}

#pragma mark - Folders

+ (NSString *)supportFolder
{
    NSError *error;
    NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    return appSupportDir.path;
}

@end
