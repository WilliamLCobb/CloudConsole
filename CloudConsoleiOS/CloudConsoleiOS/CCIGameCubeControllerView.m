//
//  CCIGameCubeControllerView.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/18/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIGameCubeControllerView.h"
#import "CCDirectionalControl.h"
@implementation CCIGameCubeControllerView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        /*  Set up Buttons  */
        //A
        [self addButtonWithFrame:CGRectMake(frame.size.width - 135,
                                            frame.size.height - 115,
                                            80,
                                            80)
                             Tag:1 << 0
                           Image:@"gcpad_a.png"
                    PressedImage:@"gcpad_a_pressed.png"];
        //B
        [self addButtonWithFrame:CGRectMake(frame.size.width - 195,
                                            frame.size.height - 100,
                                            50,
                                            50)
                             Tag:1 << 1
                           Image:@"gcpad_b.png"
                    PressedImage:@"gcpad_b_pressed.png"];
        
        //X
        [self addButtonWithFrame:CGRectMake(frame.size.width - 60,
                                            frame.size.height - 105,
                                            50,
                                            50)
                             Tag:1 << 2
                           Image:@"gcpad_x.png"
                    PressedImage:@"gcpad_x_pressed.png"];
        //Y
        [self addButtonWithFrame:CGRectMake(frame.size.width - 130,
                                            frame.size.height - 160,
                                            50,
                                            50)
                             Tag:1 << 3
                           Image:@"gcpad_y.png"
                    PressedImage:@"gcpad_y_pressed.png"];
        
        //Z
        [self addButtonWithFrame:CGRectMake(frame.size.width - 120,
                                            frame.size.height - 45,
                                            50,
                                            50)
                             Tag:1 << 4
                           Image:@"gcpad_z.png"
                    PressedImage:@"gcpad_z_pressed.png"];
        //R
        [self addButtonWithFrame:CGRectMake(frame.size.width - 80,
                                            frame.size.height/2 - 30,
                                            60,
                                            60)
                             Tag:1 << 5
                           Image:@"gcpad_r.png"
                    PressedImage:@"gcpad_r_pressed.png"];
        
        //L
        [self addButtonWithFrame:CGRectMake(20,
                                            frame.size.height/2 - 30,
                                            60,
                                            60)
                             Tag:1 << 6
                           Image:@"gcpad_l.png"
                    PressedImage:@"gcpad_l_pressed.png"];
        //Start
        [self addButtonWithFrame:CGRectMake(frame.size.width/2,
                                            frame.size.height - 45,
                                            40,
                                            40)
                             Tag:1 << 7
                           Image:@"gcpad_start.png"
                    PressedImage:@"gcpad_start_pressed.png"];
        
        //Joysticks
        CCDirectionalControl * leftJoy = [[CCDirectionalControl alloc]
                                          initWithFrame:CGRectMake(10,
                                                                   self.frame.size.height - 130,
                                                                   120,
                                                                   120)
                                          BoundsImage:@"gcpad_joystick_range.png"
                                          StickImage:@"gcpad_joystick.png"];
        leftJoy.tag = 1;
        [leftJoy addTarget:self action:@selector(joystickMoved:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:leftJoy];
    }
    return self;
}

@end
