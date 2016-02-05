//
//  CCIDevice.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/26/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BonjourHandler.h"
@interface CCIDevice : NSObject <BonjourDelegate>

@property NSString *name;
@property NSString *host;
@property uint16_t  port;
@property CFTimeInterval discoveryTime;

- (id)initWithName:(NSString *)name host:(NSString *)host port:(uint16_t)port;
@end
