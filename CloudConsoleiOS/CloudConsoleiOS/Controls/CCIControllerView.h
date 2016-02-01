//
//  CCIControllerView.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/18/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CCDirectionalControl;
typedef NS_ENUM(NSInteger, CCControllerStyle) {
    CCControllerStyleDefault,
    CCControllerStyleN64,
    CCControllerStyleGamecube,
    CCControllerStyleXBox,
    CCControllerStylePlayStation
};

@protocol CCIControllerViewDelegate <NSObject>

- (void)buttonStateChanged:(uint32_t)buttonState;
- (void)joystick:(NSInteger)joyid movedToPosition:(CGPoint)joyPosition;
@end

@interface CCIControllerView : UIView

@property uint32_t  buttonState;
@property id <CCIControllerViewDelegate> delegate;
+ (id)controllerWithFrame:(CGRect)frame Type:(CCControllerStyle)type;
- (void)addButtonWithFrame:(CGRect)frame Tag:(NSInteger) tag Image:(NSString *) image PressedImage:(NSString *)pressedImage;

- (void)joystickMoved:(CCDirectionalControl *)joystick;

@end
