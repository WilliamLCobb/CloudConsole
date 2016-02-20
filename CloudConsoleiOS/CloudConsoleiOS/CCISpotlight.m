//
//  CCISpotlight.m
//  Cloud Console
//
//  Created by Will Cobb on 2/16/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCISpotlight.h"
#define kAnimationTime 0.15

#pragma mark - SpotlightWindow

@implementation CCISpotlightWindow

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.delegate touchedScreen];
}
@end

#pragma mark - Spotlight

@interface CCISpotlight () {
    UIWindow            *oldKeyWindow;
    
    CAShapeLayer        *coverLayer;
    CGPoint             spotlightPoint;
    CCISpotlightWindow  *keyWindow;
    
    BOOL                spotlightShown;
    
    NSInteger           frameNumber;
    NSTimer             *transitionTimer;
}

@end

@implementation CCISpotlight

- (id)init
{
    if (self = [super init]) {
        frameNumber = 0;
    }
    return self;
}

- (void)beginPresentation
{
    // Not above status bar but safe
    //keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    // Above status bar
    oldKeyWindow = [[UIApplication sharedApplication] keyWindow];
    keyWindow = [[CCISpotlightWindow alloc] initWithFrame:[[UIApplication sharedApplication] keyWindow].bounds];
    [keyWindow makeKeyAndVisible];
    keyWindow.windowLevel = UIWindowLevelStatusBar;
    keyWindow.delegate = self;
    
    coverLayer = [CAShapeLayer layer];
    coverLayer.fillRule = kCAFillRuleEvenOdd;
    coverLayer.fillColor = [UIColor blackColor].CGColor;
    coverLayer.opacity = 0.5;
    [keyWindow.layer addSublayer:coverLayer];
    
    
    coverLayer.path = [self screenCoverPath].CGPath;
    
    /*  Setup Timer  */
    if (self.automaticTransitionTime <= 0) {
        [transitionTimer invalidate];
    } else {
        transitionTimer = [NSTimer scheduledTimerWithTimeInterval:self.automaticTransitionTime
                                                           target:self selector:@selector(nextFrame)
                                                         userInfo:nil repeats:YES];
    }
    [self nextFrame];
}

- (void)endPresentation
{
    [transitionTimer invalidate];
    [UIView animateWithDuration:0.3 animations:^{
        keyWindow.alpha = 0;
    } completion:^(BOOL finished) {
        [oldKeyWindow makeKeyAndVisible];
        keyWindow = nil;
    }];
    
}

- (void)touchedScreen
{
    [self nextFrame];
}

- (void)nextFrame
{
    [self.delegate CCISpotlight:self showFrame:frameNumber];
    frameNumber++;
}

- (UIBezierPath *)screenCoverPath
{
    return [UIBezierPath bezierPathWithRoundedRect:keyWindow.bounds cornerRadius:0];
}

- (UIBezierPath *)circleSpotlightPathWithRect:(CGRect)frame
{
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:frame.size.width/2];
}

- (UIBezierPath *)squareSpotlightPathWithRect:(CGRect)frame
{
    return [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:4];
}

- (void)animateFromPath:(UIBezierPath *)path1 to:(UIBezierPath *)path2 spring:(BOOL)spring
{
    CABasicAnimation *pathAnimation;
    if (spring) {
        pathAnimation = [CASpringAnimation animationWithKeyPath:@"path"];
    } else {
        pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    }
    if (!path1) {
        pathAnimation.fromValue = (__bridge id)(coverLayer.path);
    } else {
        pathAnimation.fromValue = (__bridge id)(path1.CGPath);
    }
    pathAnimation.toValue = (__bridge id)(path2.CGPath);
    pathAnimation.duration = kAnimationTime;
    [coverLayer addAnimation:pathAnimation forKey:@"animationKey"];
    coverLayer.path = path2.CGPath;
}

- (void)coverScreen
{
    coverLayer.path = [self screenCoverPath].CGPath;
}

- (void)uncoverScreen
{
    coverLayer.path = nil;
}

- (void)hideSpotlight
{
    UIBezierPath *spotPathEnd = [self screenCoverPath];
    if (spotlightShown) {
        UIBezierPath *spotlightPath = [self circleSpotlightPathWithRect:CGRectMake(spotlightPoint.x, spotlightPoint.y, 0, 0)];
        [spotPathEnd appendPath:spotlightPath];
        
        [self animateFromPath:nil to:spotPathEnd spring:YES];
        spotlightShown = NO;
    }
    
}

- (void)showCircleSpotlightAtPoint:(CGPoint)point radius:(CGFloat)radius
{
    CGFloat yCorrection = [UIApplication sharedApplication].isStatusBarHidden ? 0 : 20;
    CGFloat delay = 0;
    if (spotlightShown) {
        [self hideSpotlight];
        delay = kAnimationTime + 0.1;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIBezierPath *spotPathStart = [self screenCoverPath];
        [spotPathStart appendPath:[self circleSpotlightPathWithRect:CGRectMake(point.x, point.y + yCorrection, 0, 0)]];
        
        UIBezierPath *spotPathEnd = [self screenCoverPath];
        [spotPathEnd appendPath:[self circleSpotlightPathWithRect:CGRectMake(point.x - radius, point.y + yCorrection - radius, radius*2, radius*2)]];
        
        [self animateFromPath:spotPathStart to:spotPathEnd spring:YES];
        
        spotlightPoint = point;
        spotlightShown = YES;
    });
}

- (void)moveCircleSpotlightToPoint:(CGPoint)point radius:(CGFloat)radius
{
    CGFloat yCorrection = [UIApplication sharedApplication].isStatusBarHidden ? 0 : 20;
    if (!spotlightShown) {
        NSLog(@"Error! moving spotlight but no spotlight");
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBezierPath *spotPathEnd = [self screenCoverPath];
        [spotPathEnd appendPath:[self circleSpotlightPathWithRect:CGRectMake(point.x - radius, point.y - radius + yCorrection, radius*2, radius*2)]];
        
        [self animateFromPath:nil to:spotPathEnd spring:NO];
        
        spotlightPoint = point;
        spotlightShown = YES;
    });
}

- (void)showSquareSpotlightAtPoint:(CGPoint)point size:(CGSize)size
{
    CGFloat yCorrection = [UIApplication sharedApplication].isStatusBarHidden ? 0 : 20;
    CGFloat delay = 0;
    if (spotlightShown) {
        [self hideSpotlight];
        delay = kAnimationTime + 0.1;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIBezierPath *spotPathStart = [self screenCoverPath];
        [spotPathStart appendPath:[self squareSpotlightPathWithRect:CGRectMake(point.x, point.y + yCorrection, 0, 0)]];
        
        UIBezierPath *spotPathEnd = [self screenCoverPath];
        [spotPathEnd appendPath:[self squareSpotlightPathWithRect:CGRectMake(point.x - size.width/2, point.y + yCorrection - size.height/2, size.width, size.height)]];
        
        [self animateFromPath:spotPathStart to:spotPathEnd spring:YES];
        
        spotlightPoint = point;
        spotlightShown = YES;
    });
}

- (void)moveSquareSpotlightToPoint:(CGPoint)point size:(CGSize)size
{
    CGFloat yCorrection = [UIApplication sharedApplication].isStatusBarHidden ? 0 : 20;
    if (!spotlightShown) {
        NSLog(@"Error! moving spotlight but no spotlight");
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIBezierPath *spotPathEnd = [self screenCoverPath];
        [spotPathEnd appendPath:[self squareSpotlightPathWithRect:CGRectMake(point.x - size.width/2, point.y + yCorrection - size.height/2, size.width, size.height)]];
        
        [self animateFromPath:nil to:spotPathEnd spring:NO];
        
        spotlightPoint = point;
        spotlightShown = YES;
    });
}

@end
