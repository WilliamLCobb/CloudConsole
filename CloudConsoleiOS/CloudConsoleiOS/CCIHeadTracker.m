//
//  CCIHeadTracker.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/23/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIHeadTracker.h"

@implementation CCIHeadTracker

- (id)init
{
    if (self = [super init]) {
        self.motionManager = [[CMMotionManager alloc] init];
        self.motionManager.accelerometerUpdateInterval = .2;
        self.motionManager.gyroUpdateInterval = .2;
        
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                                 withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
                                                     [self outputAccelertionData:accelerometerData.acceleration];
                                                     if(error){
                                                         
                                                         NSLog(@"EE %@", error);
                                                     }
                                                 }];
        
        [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                        withHandler:^(CMGyroData *gyroData, NSError *error) {
                                            [self outputRotationData:gyroData.rotationRate];
                                        }];

    }
    return self;
}

-(void)outputAccelertionData:(CMAcceleration)acceleration
{
    NSLog(@"%f %f %f", acceleration.x, acceleration.y, acceleration.z);
}

-(void)outputRotationData:(CMRotationRate)rotation
{
    NSLog(@"%f %f %f", rotation.x, rotation.y, rotation.z);
}

@end
