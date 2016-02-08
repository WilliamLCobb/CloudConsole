//
//  StreamViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIStreamViewController.h"
#import "GPUImage.h"
#import "CCIHeadTracker.h"

@interface GPUImageMovie ()
-(void) processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime;
@end

@interface CCIStreamViewController () {
    GPUImageMovie   *moviePlayer;
    GPUImageView    *streamView;
    GPUImageFilter  *streamFilter;
    
    CCIControllerView   *controllerView;
    CCIHeadTracker      *headTracker;
    
    UIView          *greenLineHider;
}



@end

@implementation CCIStreamViewController

- (void)viewDidLoad
{
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft] forKey:@"orientation"];
    
    moviePlayer = [[GPUImageMovie alloc] initWithAsset:nil];
    
    streamView = [[GPUImageView alloc] init];
    streamView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:streamView];
    [self.view sendSubviewToBack:streamView];
    
    greenLineHider = [[UIView alloc] init];
    greenLineHider.backgroundColor = [UIColor blackColor];
    [self.view addSubview:greenLineHider];
    
    streamFilter = [[GPUImageFilter alloc] init];
    [streamFilter forceProcessingAtSize:streamView.sizeInPixels];
    
    [moviePlayer addTarget:streamFilter];
    [streamFilter addTarget:streamView];
    
    CGRect controlRect = CGRectZero;
    controlRect.size = [self currentScreenSizeAlwaysLandscape:YES];
    controllerView = [CCIControllerView controllerWithFrame:controlRect Type:CCControllerStyleGamecube];
    controllerView.delegate = self;
    [self.view addSubview:controllerView];
    //headTracker = [[CCIHeadTracker alloc] init];
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [self setDispayRatio:4.0/3];
}

- (void)setDispayRatio:(CGFloat) displayRatio  // Width/height
{
    NSLog(@"Setting ratio");
    CGRect streamRect = streamView.frame;
    
    CGFloat windowWidth = MIN(self.view.frame.size.width, self.view.frame.size.height * displayRatio);
    streamRect.size.width = windowWidth;
    streamRect.size.height = windowWidth / displayRatio;
    dispatch_async(dispatch_get_main_queue(), ^{
        streamView.frame = streamRect;
        CGSize displaySize = [self currentScreenSizeAlwaysLandscape:YES];
        streamView.center = CGPointMake(displaySize.width/2, displaySize.height/2);
        greenLineHider.frame = CGRectMake(streamView.frame.origin.x + streamView.frame.size.width-2, 0, 2, self.view.frame.size.height);
    });
}

- (void)displayFrame:(CVImageBufferRef)frame
{
    [moviePlayer processMovieFrame:frame withSampleTime:kCMTimeZero];
    CGSize streamSize = CVImageBufferGetDisplaySize(frame);
    if (fabs((streamView.frame.size.width/streamView.frame.size.height) -
             streamSize.width / streamSize.height) > 0.001) { //Ratio change
        //NSLog(@"Changing Size: %@ %@", NSStringFromCGSize(streamSize), NSStringFromCGSize(streamView.frame.size));
        [self setDispayRatio:streamSize.width / streamSize.height];
    }
}

-(CGSize)currentScreenSizeAlwaysLandscape:(BOOL)landscape
{
    if (!landscape)
        return [UIScreen mainScreen].bounds.size;
    //Get portrait size
    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds);
    CGFloat height = CGRectGetHeight(screenBounds);
    if ([self isPortrait]){
        return CGSizeMake(height, width);
    }
    return CGSizeMake(width, height);
}

-(BOOL) isPortrait
{
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
}

-(BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - Controls

- (void)buttonStateChanged:(uint32_t)buttonState
{
    [self.streamManager sendButtonState:buttonState];
}

- (void)joystick:(NSInteger)joyid movedToPosition:(CGPoint)joyPosition
{
    [self.streamManager sendDirectionalState:joyPosition forJoy:joyid];
}

#pragma mark - Callbacks

- (void)closedStream
{
    NSLog(@"CLosed stream");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
