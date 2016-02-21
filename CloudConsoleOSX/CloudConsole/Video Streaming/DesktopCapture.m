//
//  DesktopCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/24/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

//
//#import "DesktopCapture.h"
//#import <IOKit/graphics/IOGraphicsLib.h>
//#import <IOSurface/IOSurface.h>
//#import "CSIOSurfaceLayer.h"
//
//#import <pthread.h>
//
//
//@implementation DesktopCapture
//
//@synthesize activeVideoDevice = _activeVideoDevice;
//@synthesize videoCaptureFPS = _videoCaptureFPS;
//@synthesize renderType = _renderType;
//
//
//
//
//
//-(void)encodeWithCoder:(NSCoder *)aCoder
//{
//    [super encodeWithCoder:aCoder];
//    
//    [aCoder encodeInt:self.width forKey:@"width"];
//    [aCoder encodeInt:self.height forKey:@"height"];
//    [aCoder encodeInt:self.region_width forKey:@"region_width"];
//    [aCoder encodeInt:self.region_height forKey:@"region_height"];
//    [aCoder encodeInt:self.x_origin forKey:@"x_origin"];
//    [aCoder encodeInt:self.y_origin forKey:@"y_origin"];
//    [aCoder encodeDouble:self.videoCaptureFPS forKey:@"videoCaptureFPS"];
//    [aCoder encodeBool:self.showCursor forKey:@"showCursor"];
//    [aCoder encodeInt:self.renderType forKey:@"renderType"];
//}
//
//
//
//-(id) initWithCoder:(NSCoder *)aDecoder
//{
//    
//    if (self = [super initWithCoder:aDecoder])
//    {
//        _width = [aDecoder decodeIntForKey:@"width"];
//        _height = [aDecoder decodeIntForKey:@"height"];
//        _videoCaptureFPS = [aDecoder decodeDoubleForKey:@"videoCaptureFPS"];
//        _showCursor = [aDecoder decodeBoolForKey:@"showCursor"];
//        _region_width = [aDecoder decodeIntForKey:@"region_width"];
//        _region_height = [aDecoder decodeIntForKey:@"region_height"];
//        _x_origin = [aDecoder decodeIntForKey:@"x_origin"];
//        _y_origin = [aDecoder decodeIntForKey:@"y_origin"];
//        _renderType = [aDecoder decodeIntForKey:@"renderType"];
//        
//        
//    }
//    
//    [self setupDisplayStream];
//    return self;
//}
//
//
//
//-(id) init
//{
//    if (self = [super init])
//    {
//        _capture_queue = dispatch_queue_create("Desktop Capture Queue", DISPATCH_QUEUE_SERIAL);
//
//        self.canProvideTiming = YES;
//        self.videoCaptureFPS = 60.0f;
//        self.showCursor = YES;
//        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationTerminating:) name:NSApplicationWillTerminateNotification object:nil];
//        
//
//    }
//
//    return self;
//    
//}
//
//
//-(void)frameTick
//{
//    
//    if (self.renderType == kCSRenderOnFrameTick)
//    {
//        
//        [self updateLayersWithBlock:^(CALayer *layer) {
//            [((CSIOSurfaceLayer *)layer) setNeedsDisplay];
//        }];
//    }
//    
//}
//
//
//-(CALayer *)createNewLayer
//{
//    
//    CSIOSurfaceLayer *newLayer = [CSIOSurfaceLayer layer];
//    
//    if (self.renderType == kCSRenderAsync)
//    {
//        newLayer.asynchronous = YES;
//    } else {
//        newLayer.asynchronous = NO;
//    }
//    
//    return newLayer;
//}
//
//
//-(void)applicationTerminating:(NSApplication *)sender
//{
//    [self stopDisplayStream];
//}
//
//
//
//-(CSAbstractCaptureDevice *)activeVideoDevice
//{
//    return _activeVideoDevice;
//}
//
//
//-(void) setActiveVideoDevice:(CSAbstractCaptureDevice *)newDev
//{
//    
//    _activeVideoDevice = newDev;
//    self.currentDisplay = [[newDev captureDevice] unsignedIntValue];
//    self.captureName = newDev.captureName;
//    
//    [self setupDisplayStream];
//}
//
//
//-(void)setRenderType:(frame_render_behavior)renderType
//{
//    
//    
//    BOOL asyncValue = NO;
//    if (renderType == kCSRenderAsync)
//    {
//        asyncValue = YES;
//    }
//    
//    
//    [self updateLayersWithBlock:^(CALayer *layer) {
//        
//        ((CSIOSurfaceLayer *)layer).asynchronous = asyncValue;
//    }];
//    
//    _renderType = renderType;
//}
//
//
//-(frame_render_behavior)renderType
//{
//    return _renderType;
//}
//
//
//-(bool)setupDisplayStream
//{
//
//    int width;
//    int height;
//    
//    
//    if (_displayStreamRef)
//    {
//        [self stopDisplayStream];
//    }
//    
//
//    
//    if (!self.currentDisplay)
//    {
//        return NO;
//    }
//    
//    
//    
//    
//    
//    NSNumber *minframetime = [NSNumber numberWithFloat:(1000.0/(self.videoCaptureFPS*1000))];
//
//    CGRect displaySize = CGDisplayBounds(self.currentDisplay);
//    
//    width = displaySize.size.width - self.x_origin;
//    height = displaySize.size.height - self.y_origin;
//    
//    if (self.region_width)
//    {
//        width = self.region_width;
//    }
//    
//    if (self.region_height)
//    {
//        height = self.region_height;
//    }
//    
//    if (self.width && self.height)
//    {
//        width = self.width;
//        height = self.height;
//    }
//    
//
//    CFDictionaryRef rectDict;
//
//    int rect_width;
//    int rect_height;
//    
//    if (self.region_width)
//    {
//        rect_width = self.region_width;
//    } else {
//        rect_width = displaySize.size.width - self.x_origin;
//    }
//    
//    if (self.region_height)
//    {
//        rect_height = self.region_height;
//    } else {
//        rect_height = displaySize.size.height - self.y_origin;
//    }
//
//    rectDict = CGRectCreateDictionaryRepresentation(CGRectMake(self.x_origin, self.y_origin, rect_width, rect_height));
//    
//    
//    NSDictionary *opts = @{(NSString *)kCGDisplayStreamQueueDepth : @8, (NSString *)kCGDisplayStreamMinimumFrameTime : minframetime, (NSString *)kCGDisplayStreamPreserveAspectRatio: @YES, (NSString *)kCGDisplayStreamShowCursor:@(self.showCursor), (NSString *)kCGDisplayStreamSourceRect: (__bridge NSDictionary *)rectDict};
//    
//    
//    
//
//    __weak __typeof__(self) weakSelf = self;
//    
//    
//    _displayStreamRef = CGDisplayStreamCreateWithDispatchQueue(self.currentDisplay, width, height,  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)(opts), _capture_queue, ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
//        
//
//        CFAbsoluteTime nowTime = CFAbsoluteTimeGetCurrent();
//        _lastFrame = nowTime;
//        
//        _lastFrame = nowTime;
//        
//        
//        if (!weakSelf)
//        {
//            return;
//        }
//        
//        __typeof__(self) strongSelf = weakSelf;
//        
//        
//        
//        if (status == kCGDisplayStreamFrameStatusStopped)
//        {
//            if (strongSelf->_displayStreamRef)
//            {
//                CFRelease(strongSelf->_displayStreamRef);
//            }
//            
//            
//        }
//        
//        
//        if (status == kCGDisplayStreamFrameStatusFrameComplete && frameSurface)
//        {
//            [strongSelf updateLayersWithBlock:^(CALayer *layer) {
//
//                ((CSIOSurfaceLayer *)layer).ioSurface = frameSurface;
//                if (self.renderType == kCSRenderFrameArrived)
//                {
//                    
//                    
//                    //dispatch through the main queue because otherwise the display stream events bounce between threads and confuse core animation
//                  //dispatch_async(dispatch_get_main_queue(), ^{
//                        [((CSIOSurfaceLayer *)layer) setNeedsDisplay];
//                // });
//                }
//
//
//            }];
//            [self frameArrived];
//
//            
//            
//        }
//    });
//
//    CGDisplayStreamStart(_displayStreamRef);
//    
//    return YES;
//}
//
//
//
//
//
//-(bool)stopDisplayStream
//{
//    
//    if (_displayStreamRef)
//    {
//        CGDisplayStreamStop(_displayStreamRef);
//    }
//    
//  
//    @synchronized(self) {
//        _currentImg = nil;
//        
//    }
//
//  
//    return YES;
//}
//
//-(bool)providesAudio
//{
//    return NO;
//}
//
//
//-(bool)providesVideo
//{
//    return YES;
//}
//
//
//-(NSArray *) availableVideoDevices
//{
//    
//    CGDirectDisplayID display_ids[15];
//    uint32_t active_display_count;
//    
//    CGGetActiveDisplayList(15, display_ids, &active_display_count);
//    
//    NSMutableArray *retArray = [[NSMutableArray alloc] init];
//    
//    
//    
//    for(int i = 0; i < active_display_count; i++)
//    {
//        CGDirectDisplayID disp_id = display_ids[i];
//        NSString *displayName;
//        
//        NSDictionary *deviceInfo = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(CGDisplayIOServicePort(disp_id), kIODisplayOnlyPreferredName));
//        NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
//        if ([localizedNames count] > 0)
//        {
//            
//            displayName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
//            
//        } else {
//            displayName = @"????";
//        }
//        
//        NSNumber *display_id_obj = [NSNumber numberWithLong:disp_id];
//        NSString *display_id_uniq = [NSString stringWithFormat:@"%ud", disp_id];
//        
//        
//        [retArray addObject:[[CSAbstractCaptureDevice alloc] initWithName:displayName device:display_id_obj uniqueID:display_id_uniq]];
//    }
//    
//    return (NSArray *)retArray;
//    
//}
//
//
//+ (NSString *)label
//{
//    return @"Desktop Capture";
//}
//
//
//+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
//{
//    return [NSSet setWithObjects:@"width", @"height", @"videoCaptureFPS", @"x_origin", @"y_origin", @"region_width", @"region_height", nil];
//}
//
//
//- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    
//    
//    if ([keyPath isEqualToString:@"propertiesChanged"])
//    {
//        [self setupDisplayStream];
//    }
//    
//}
//
//
//-(void)willDelete
//{
//    [self stopDisplayStream];
//
//}
//
//-(void)dealloc
//{
//    [self removeObserver:self forKeyPath:@"propertiesChanged"];
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//}
//
//
//@end
