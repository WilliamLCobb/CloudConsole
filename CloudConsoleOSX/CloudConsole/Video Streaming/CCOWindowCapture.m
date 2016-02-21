//
//  ScreenGraber.m
//  GPUBilgeBot
//
//  Created by Will Cobb on 3/8/15.
//  Copyright (c) 2015 Apprentice Media LLC. All rights reserved.
//

#import "CCOWindowCapture.h"

@interface CCOWindowCapture () {
    pid_t appPid;
    NSInteger windowId;
    CGRect _windowRect;
    CFTimeInterval lastRectUpdate;
}

@end

@implementation CCOWindowCapture


- (id)initWithPid:(pid_t)pid
{
    if (self = [super init]) {
        appPid  = pid;
        NSArray *windows = [self capturableWindows];
        if (windows.count == 0) {
            NSLog(@"Error capturing, no windows");
            return nil;
        }
        [self captureWindowWithId:[windows[0][@"kCGWindowNumber"] intValue]];
    }
    
    return self;
}

-(NSArray *)capturableWindows
{
    CGWindowListOption opt = kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements;
    CFArrayRef windowids =CGWindowListCreate(opt, kCGNullWindowID); //Gets every onscreen window
    NSArray *windows = CFBridgingRelease(CGWindowListCreateDescriptionFromArray(windowids));
    //
    windows = [windows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(kCGWindowOwnerPID == %d)", appPid]]; //Filters for window Name
    CFRelease(windowids);
    return windows;
}

- (void)captureWindowWithId:(int)newWindowId
{
    windowId = newWindowId;
    _windowRect = [self windowRect];
    lastRectUpdate = CACurrentMediaTime();
}

- (id)initWithApplicationName:(NSString *)applicationName
{
    if (self = [self init]) {
        CGWindowListOption opt = kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements;
        CFArrayRef windowids =CGWindowListCreate(opt, kCGNullWindowID); //Gets every onscreen window
        NSArray *windows = CFBridgingRelease(CGWindowListCreateDescriptionFromArray(windowids));
        //
        windows = [windows filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(kCGWindowOwnerName == %@)", applicationName]]; //Filters for window Name
        if (windows.count < 1) {
            NSLog(@"Error, no window found named: %@", applicationName);
            return nil;
        } else if (windows.count == 0) {
            windowId = [windows[0][@"kCGWindowNumber"] integerValue];
        } else {
            NSLog(@"Windows Found: %@", windows);
            NSLog(@"Error... more than one window found, using first");
            windowId = [windows[0][@"kCGWindowNumber"] integerValue];
        }
    }
    return self;
}

- (CGImageRef)captureFrame
{
    if (CACurrentMediaTime() - lastRectUpdate > 1) { //Update window rect every second
        CGRect newRect = [self windowRect];
        if (!CGSizeEqualToSize(newRect.size, _windowRect.size) || CGPointEqualToPoint(newRect.origin, _windowRect.origin)) {
            _windowRect = newRect;
            [self.delegate windowSizeChanged];
        }
    }
    
    return CGWindowListCreateImage(_windowRect, kCGWindowListOptionIncludingWindow, (int)windowId, (kCGWindowImageBoundsIgnoreFraming|kCGWindowImageBestResolution)); //kCGWindowImageBoundsIgnoreFraming|
}

- (CGSize)windowSize
{
    return _windowRect.size;
}

-(CGRect) windowRect
{
    NSDictionary * windowInfo = [self windowInformation];
    return CGRectMake([windowInfo[@"kCGWindowBounds"][@"X"] integerValue],
                      [windowInfo[@"kCGWindowBounds"][@"Y"] integerValue] + 22,
                      [windowInfo[@"kCGWindowBounds"][@"Width"] integerValue]+1,
                      [windowInfo[@"kCGWindowBounds"][@"Height"] integerValue] - 20);
    
}

-(NSDictionary *)windowInformation
{
    CFArrayRef windowids =CGWindowListCreate(kCGWindowListOptionIncludingWindow, (int)windowId);
    NSArray *windowInfo = CFBridgingRelease(CGWindowListCreateDescriptionFromArray(windowids));
    CFRelease(windowids);
    
    if (windowInfo.count == 0) {
        [self.delegate windowClosed];
        return nil;
    }
    return [windowInfo objectAtIndex:0];
}

@end
