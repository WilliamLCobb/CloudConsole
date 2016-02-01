//
//  CCDirectionalControl.h
//  CC
//
//  Created by CC
//  Copyright (c) 2014 CC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, CCDirectionalControlDirection) {
    CCDirectionalControlDirectionUp     = 1 << 0,
    CCDirectionalControlDirectionDown   = 1 << 1,
    CCDirectionalControlDirectionLeft   = 1 << 2,
    CCDirectionalControlDirectionRight  = 1 << 3,
};

typedef NS_ENUM(NSInteger, CCDirectionalControlStyle) {
    CCDirectionalControlStyleDPad = 0,
    CCDirectionalControlStyleJoystick = 1,
};

@interface CCDirectionalControl : UIControl

@property (readonly, nonatomic) CCDirectionalControlDirection direction;
@property (assign, nonatomic) CCDirectionalControlStyle style;

- (id)initWithFrame:(CGRect)frame BoundsImage:(NSString *)boundsImage StickImage:(NSString *)stickImage;
- (id)initWithFrame:(CGRect)frame DPadImages:(NSArray <UIImage *> *)dpadImages;

- (CGPoint)joyLocation;
- (void) frameUpdated;

@end
