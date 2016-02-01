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

- (void)addButtonWithFrame:(CGRect)frame Tag:(NSInteger) tag Image:(NSString *) image PressedImage:(NSString *)pressedImage
{
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    button.tag = tag;
    [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    if (pressedImage)
        [button setImage:[UIImage imageNamed:pressedImage] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    //[button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDragEnter];
    //[button addTarget:self action:@selector(buttonUp:)   forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(buttonUp:)   forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
}

- (void)buttonDown:(UIButton *)sender
{
    _buttonState ^= sender.tag;
    if ([self.delegate respondsToSelector:@selector(buttonStateChanged:)]) {
        [self.delegate buttonStateChanged:self.buttonState];
    } else {
        NSLog(@"Error. Delegate doesnt respond to buttonStateChanged:");
    }
}

- (void)buttonUp:(UIButton *)sender
{
    _buttonState ^= sender.tag;
    if ([self.delegate respondsToSelector:@selector(buttonStateChanged:)]) {
        [self.delegate buttonStateChanged:self.buttonState];
    } else {
        NSLog(@"Error. Delegate doesnt respond to buttonStateChanged:");
    }
}

- (void)joystickMoved:(CCDirectionalControl *)joystick
{
    [self.delegate joystick:joystick.tag movedToPosition:(CGPoint)joystick.joyLocation];
}

@end
