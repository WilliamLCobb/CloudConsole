//
//  ScreenGraber.h
//  GPUBilgeBot
//
//  Created by Will Cobb on 3/8/15.
//  Copyright (c) 2015 Apprentice Media LLC. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@protocol CCOWindowCaptureDelegate <NSObject>

- (void)windowSizeChanged;
- (void)windowClosed;

@end

@interface CCOWindowCapture : NSObject

- (id)initWithPid:(pid_t)pid;
- (id)initWithApplicationName:(NSString *)applicationName;
- (CGImageRef)captureFrame;
- (CGSize)windowSize;

@property id <CCOWindowCaptureDelegate> delegate;

@end
