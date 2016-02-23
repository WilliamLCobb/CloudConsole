//
//  StreamViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  https://github.com/liuzhiyi1992/SpreadButton
#import "CCIStreamViewController.h"
#import "GPUImage.h"
#import "CCIHeadTracker.h"
#import "FBShimmeringView.h"
#import "ZYSpreadButton.h"
#import "AppDelegate.h";
@interface GPUImageMovie ()
-(void) processMovieFrame:(CVPixelBufferRef)movieFrame withSampleTime:(CMTime)currentSampleTime;
@end


@interface CCIStreamViewController () {
    GPUImageMovie   *moviePlayer;
    GPUImageView    *streamView;
    GPUImageFilter  *streamFilter;
    
    CCIControllerView   *controllerView;
    CCIHeadTracker      *headTracker;
    
    UIView              *greenLineHider;
    FBShimmeringView    *shimmerView;
    ZYSpreadButton      *spreadButton;
    ZYSpreadSubButton   *lock;
    ZYSpreadSubButton   *unlock;
    
}



@end

@implementation CCIStreamViewController

- (void)viewDidLoad
{
    AppDelegate.sharedInstance.forcePortrait = NO;
    
    __weak CCIStreamViewController *weakSelf = self;
    
    moviePlayer = [[GPUImageMovie alloc] initWithAsset:nil];
    
    streamView = [[GPUImageView alloc] init];
    streamView.alpha = 0;
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
    controllerView.alpha = 0;
    [self.view addSubview:controllerView];
    //headTracker = [[CCIHeadTracker alloc] init];
    
    shimmerView = [[FBShimmeringView alloc] initWithFrame:CGRectMake(0, 0, 400, 100)];
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:shimmerView.bounds];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    loadingLabel.text = @"Connecting";
    loadingLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:60];
    loadingLabel.textColor = [UIColor colorWithWhite:0.9 alpha:1];
    shimmerView.contentView = loadingLabel;
    shimmerView.center =  CGPointMake(controllerView.center.x, controllerView.center.y - 20); //self.view is still potrait
    // Start shimmering.
    shimmerView.shimmering = YES;
    [self.view addSubview:shimmerView];
    
    spreadButton = [[ZYSpreadButton alloc] initWithBackgroundImage:[UIImage imageNamed:@"plus35"]
                                                    highlightImage:[UIImage imageNamed:@"plus35"]
                                                          position:CGPointMake(self.view.frame.size.width/2, 30)];
    spreadButton.powerButton.layer.cornerRadius = spreadButton.powerButton.frame.size.width/2;
    spreadButton.powerButton.clipsToBounds = YES;
    spreadButton.radius = 80;
    spreadButton.positionMode = SpreadPositionModeTouchBorder;
    spreadButton.alpha = 0.5;
    spreadButton.mode = SpreadModeFlowerSpread;
    spreadButton.buttonWillSpreadBlock = ^(ZYSpreadButton *button){
        [UIView animateWithDuration:0.1 animations:^{
            button.alpha = 1;
        }];
        [weakSelf.streamManager pause];
    };
    spreadButton.buttonDidSpreadBlock = ^(ZYSpreadButton *button){};
    spreadButton.buttonWillCloseBlock = ^(ZYSpreadButton *button){
        [UIView animateWithDuration:0.1 animations:^{
            button.alpha = 0.5;
        }];
        [weakSelf.streamManager resume];
    };
    spreadButton.buttonDidCloseBlock = ^(ZYSpreadButton *button){};
    spreadButton.direction = SpreadDirectionBottom;
    
    /*  Settings  */
    ZYSpreadSubButton *settings = [[ZYSpreadSubButton alloc] initWithBackgroundImage:[UIImage imageNamed:@"gear35"] highlightImage:[UIImage imageNamed:@"gear35"] clickedBlock:^(int index, UIButton *sender) {
        
    }];
    settings.layer.cornerRadius = settings.frame.size.width/2;
    settings.clipsToBounds = YES;
    
    /*  Exit  */
    ZYSpreadSubButton *exit = [[ZYSpreadSubButton alloc] initWithBackgroundImage:[UIImage imageNamed:@"stop35"] highlightImage:[UIImage imageNamed:@"stop35"] clickedBlock:^(int index, UIButton *sender) {
        [self.streamManager closeStream];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    exit.layer.cornerRadius = exit.frame.size.width/2;
    exit.clipsToBounds = YES;
    
    /*  Lock  */
    lock = [[ZYSpreadSubButton alloc] initWithBackgroundImage:[UIImage imageNamed:@"lock35"] highlightImage:[UIImage imageNamed:@"lock35"] clickedBlock:^(int index, UIButton *sender) {
        spreadButton.positionMode = SpreadPositionModeFixed;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [unlock setHidden:NO];
            [lock setHidden:YES];
            unlock.alpha = 1;
            lock.alpha = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [spreadButton setSubButtons:@[settings, unlock, exit]];
            });
        });
        
    }];
    lock.layer.cornerRadius = lock.frame.size.width/2;
    lock.clipsToBounds = YES;
    
    /*  Unlock  */
    unlock = [[ZYSpreadSubButton alloc] initWithBackgroundImage:[UIImage imageNamed:@"unlock35"] highlightImage:[UIImage imageNamed:@"unlock35"] clickedBlock:^(int index, UIButton *sender) {
        spreadButton.positionMode = SpreadPositionModeTouchBorder;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [unlock setHidden:YES];
            [lock setHidden:NO];
            unlock.alpha = 0;
            lock.alpha = 1;
            dispatch_async(dispatch_get_main_queue(), ^{
                [spreadButton setSubButtons:@[settings, lock, exit]];
            });
        });
        
        
    }];
    unlock.layer.cornerRadius = lock.frame.size.width/2;
    unlock.clipsToBounds = YES;
    
    [spreadButton setSubButtons:@[settings, unlock, exit]];
    [controllerView addSubview:spreadButton];
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
    //First frame
    if (shimmerView.alpha == 1) {
        shimmerView.alpha = 0.99;
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                shimmerView.alpha = 0;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 animations:^{
                    controllerView.alpha = 1;
                    streamView.alpha = 1;
                }];
            }];
        });
    }
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
