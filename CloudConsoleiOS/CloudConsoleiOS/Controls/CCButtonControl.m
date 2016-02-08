//
//  ButtonControl.m
//  CC
//
//  Created by Riley Testut on 7/5/13.
//  Copyright (c) 2014 CC. All rights reserved.
//

#import "CCButtonControl.h"

@interface CCDirectionalControl ()

@property (strong, nonatomic) UIImageView *backgroundImageView;

@end

@interface CCButtonControl ()

@property (readwrite, nonatomic) CCButtonControlButton selectedButtons;

@end

@implementation CCButtonControl

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.backgroundImageView.image = [UIImage imageNamed:@"ABXYPad"];
    }
    return self;
}

- (CCButtonControlButton)selectedButtons {
    return (CCButtonControlButton)self.direction;
}

@end
