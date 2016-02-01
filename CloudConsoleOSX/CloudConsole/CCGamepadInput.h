//
//  CCGamepadInput.h
//  CloudConsole
//
//  Created by Will Cobb on 1/16/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCGamepadInput : NSObject

- (void)setLeftJoyX:(int8_t) x Y:(int8_t)y;
- (void)pressA;
- (void)setButtonState:(uint16_t)buttonState;

@end
