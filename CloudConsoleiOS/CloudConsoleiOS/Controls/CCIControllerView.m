//
//  CCIControllerView.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/18/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIControllerView.h"
#import "CCIGameCubeControllerView.h"
#import "CCDirectionalControl.h"

@interface CCIControllerView () {
    NSMutableArray *buttons;
}

@end

@implementation CCIControllerView

+ (id)controllerWithFrame:(CGRect)frame Type:(CCControllerStyle)type;
{
    id instance;
    switch (type) {
        case CCControllerStyleGamecube:
            instance = [[CCIGameCubeControllerView alloc] initWithFrame:frame];
            break;
            
        default:
            return nil;
            break;
    }
    [instance setButtonState:0];
    return instance;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        buttons = [NSMutableArray array];
    }
    return self;
}

- (void)addButtonWithFrame:(CGRect)frame Tag:(NSInteger) tag Image:(NSString *) image PressedImage:(NSString *)pressedImage
{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.tag = tag;
    [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    if (pressedImage)
        [button setImage:[UIImage imageNamed:pressedImage] forState:UIControlStateHighlighted];
    //[button addTarget:self action:@selector(buttonDown:)   forControlEvents:UIControlEventAllEvents];
    button.userInteractionEnabled = NO;
    [self addSubview:button];
    [buttons addObject:button];
}

- (void)dpadChanged:(CCDirectionalControl *)dpad
{
    _buttonState &=  ~(15 << dpad.tag); //Clear the 4 bits
    _buttonState |= (dpad.direction << dpad.tag); //Set the 4 bits
    if ([self.delegate respondsToSelector:@selector(buttonStateChanged:)]) {
        [self.delegate buttonStateChanged:self.buttonState];
    } else {
        NSLog(@"Error. Delegate doesnt respond to buttonStateChanged:");
    }
}

- (NSString *)getBitStringFor32:(uint32_t)value {
    NSString *bits = @"";
    
    for(int i = 0; i < 32; i ++) {
        bits = [NSString stringWithFormat:@"%i%@", value & (1 << i) ? 1 : 0, bits];
    }
    
    return bits;
}

- (void)joystickMoved:(CCDirectionalControl *)joystick
{
    [self.delegate joystick:joystick.tag movedToPosition:(CGPoint)joystick.joyLocation];
}

/*- (void)buttonChanged:(UIButton *)sender
{
    if (sender.highlighted) {
        NSLog(@"highlighted");
        _buttonState |= sender.tag;
    } else {
        NSLog(@"not highlighted");
        _buttonState &= ~sender.tag;
    }
    if ([self.delegate respondsToSelector:@selector(buttonStateChanged:)]) {
        [self.delegate buttonStateChanged:self.buttonState];
    } else {
        NSLog(@"Error. Delegate doesnt respond to buttonStateChanged:");
    }
}*/

- (void)trackTouches:(NSSet<UITouch *> *)touches
{
    uint32_t added = 0;
    CGPoint touchPoint;
    for (UIButton *button in buttons) {
        for (UITouch *touch in touches) {
            touchPoint = [touch locationInView:self];
            if (CGRectContainsPoint(button.frame, touchPoint)) {
                //NSLog(@"Pressing Button: %ld", button.tag);
                _buttonState |= button.tag;
                added |= button.tag;
                button.highlighted = YES;
            } else if (!button & added) {
                //NSLog(@"%@ not in %@", NSStringFromCGPoint(touchPoint), NSStringFromCGRect(button.frame));
                _buttonState &= ~button.tag;
                button.highlighted = NO;
            }
        }
    }
    if ([self.delegate respondsToSelector:@selector(buttonStateChanged:)]) {
        [self.delegate buttonStateChanged:self.buttonState];
    } else {
        NSLog(@"Error. Delegate doesnt respond to buttonStateChanged:");
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self trackTouches:touches];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self trackTouches:touches];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UIButton *button in buttons) {
        button.highlighted = NO;
    }
    if ([self.delegate respondsToSelector:@selector(buttonStateChanged:)]) {
        [self.delegate buttonStateChanged:0];
    } else {
        NSLog(@"Error. Delegate doesnt respond to buttonStateChanged:");
    }
}

@end
