//
//  ButtonControl.h
//  CC
//
//  Created by CC on 7/5/13.
//  Copyright (c) 2014 CC. All rights reserved.
//

#import "CCDirectionalControl.h"

// This class really doesn't do much. It's basically here to make the code easier to read, but also in case of future expansion.

// Below are identical to the superclass variants, just renamed for clarity
typedef NS_ENUM(NSInteger, CCButtonControlButton) {
    CCButtonControlButtonX     = 1 << 0,
    CCButtonControlButtonB     = 1 << 1,
    CCButtonControlButtonY     = 1 << 2,
    CCButtonControlButtonA     = 1 << 3,
};

@interface CCButtonControl : CCDirectionalControl

@property (readonly, nonatomic) CCButtonControlButton selectedButtons;

@end
