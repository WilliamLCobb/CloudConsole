//
//  CCUdpBuffer.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/23/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCUdpBuffer : NSObject

@property uint32_t tag;

+ (CCUdpBuffer *)bufferWithTag:(uint32_t)tag;

- (NSData *)consumeData:(NSData *)data;

@end
