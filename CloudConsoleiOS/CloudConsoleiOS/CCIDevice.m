//
//  CCIDevice.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/26/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIDevice.h"
#import <UIKit/UIKit.h>

@implementation CCIDevice

- (id)initWithName:(NSString *)name host:(NSString *)host port:(uint16_t)port
{
    if (self = [super init]) {
        self.name = name;
        self.host = host;
        self.port = port;
        self.discoveryTime = CACurrentMediaTime();
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        self.name = [coder decodeObjectForKey:@"name"];
        self.host = [coder decodeObjectForKey:@"host"];
        self.port = (uint16_t)[coder decodeIntForKey:@"port"];
        self.discoveryTime = [coder decodeDoubleForKey:@"time"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.host forKey:@"host"];
    [coder encodeInteger:self.port forKey:@"port"];
    [coder encodeDouble:self.discoveryTime forKey:@"time"];
}

- (BOOL) isEqual:(id)object
{
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
