//
//  AppDelegate.m
//  CloudConsole
//
//  Created by Will Cobb on 1/5/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "AppDelegate.h"
#import <mach/mach.h>
#import <mach/mach_time.h>
#import "CCOServer.h"

@interface AppDelegate () {
    
}
    
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    if ([[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]) {
        self.activity = [[NSProcessInfo processInfo] beginActivityWithOptions:0x00FFFFFF reason:@"receiving OSC messages"];
    }
    [[CCOServer sharedInstance] start];
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:25.0];
    self.statusItem.image = [NSImage imageNamed:@"menuIconTemplate"];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Cloud Console"];
    [menu addItemWithTitle:@"Cloud Console: Running" action:@selector(nothing) keyEquivalent:@""];
    
    NSString *IP = [[CCOServer sharedInstance] currentIP];
    [menu addItemWithTitle:[NSString stringWithFormat:@"IP: %@", IP] action:@selector(nothing) keyEquivalent:@""];
    [menu insertItem:[NSMenuItem separatorItem] atIndex:1];
    [menu addItemWithTitle:@"Quit" action:@selector(quitApplication) keyEquivalent:@"Q"];
    self.statusItem.menu = menu;
    
}

- (void)nothing
{
    
}


- (void)quitApplication
{
    [NSApp terminate:self];
}

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

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    self.statusItem.menu = nil;
}



@end
