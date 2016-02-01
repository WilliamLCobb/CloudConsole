//
//  CCIDevice.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/26/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIDevice.h"

@implementation CCIDevice

- (id)initWithName:(NSString *)name host:(NSString *)host port:(uint16_t)port
{
    if (self = [super init]) {
        self.name = name;
        self.host = host;
        self.port = port;
    }
    return self;
}

- (BOOL) isEqual:(id)object
{
    NSLog(@"Comparing");
    NSString *objectClass = NSStringFromClass([object class]);
    if ([objectClass isEqualToString:@"CCIDevice"]) {
        CCIDevice *other = object;
        return [other.name isEqualToString:self.name];
    } else if ([objectClass isEqualToString:@"NSNetService"]) {
        NSNetService *other = object;
        return [other.name isEqualToString:self.name];
    }
    NSLog(@"Error, unknown device compare");
    return NO;
}

@end
