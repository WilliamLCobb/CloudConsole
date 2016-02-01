//
//  CCUdpBuffer.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/23/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCUdpBuffer.h"
#import "CCNetworkProtocol.h"

@interface CCUdpBuffer () {
    NSMutableData   *buffer;
    uint32_t        blocksRemaining;
    uint32_t        totalDataSize;
    uint32_t        totalBlocks;
}

@end

@implementation CCUdpBuffer

+(CCUdpBuffer *)bufferWithTag:(uint32_t)tag
{
    CCUdpBuffer *buffer = [CCUdpBuffer new];
    buffer.tag = tag;
    return buffer;
}

- (NSData *)consumeData:(NSData *)data
{
    uint32_t *message = (uint32_t *)data.bytes;
    switch (message[0]) {
        case CCNetworkStreamBeginBlock:
            if (blocksRemaining != 0) {
                NSLog(@"Lost a block of data");
            }
            blocksRemaining = message[1];
            totalBlocks = blocksRemaining;
            totalDataSize = message[2];
            /// Better way
            //NSLog(@"Begin: %lu, %d, %ld", data.length - 12, blocksRemaining, (long)totalDataSize);
            buffer = [NSMutableData dataWithBytes:&_tag length:4];
            if (totalDataSize <= CCNetworkUDPDataSize) { //Single Packet
                [buffer appendData:[NSMutableData dataWithBytes:(uint8_t *)data.bytes + 12 length:totalDataSize]];
            } else {
                [buffer appendData:[NSMutableData dataWithLength:totalDataSize]];
                [buffer replaceBytesInRange:NSMakeRange(4, CCNetworkUDPDataSize)
                                  withBytes:(uint8_t *)data.bytes + 12 length:CCNetworkUDPDataSize];
            }
            blocksRemaining--;
            break;
            
        case CCNetworkStreamBlockNumber:
        {
            if (totalDataSize == 0) {
                NSLog(@"Warning: Got a block before a begin!");
                return nil;
            }
            uint32_t blockNumber = message[1];
            if (CCNetworkUDPDataSize * blockNumber + data.length-12 > buffer.length) {
                NSLog(@"Error, tried to write outside buffer");
                return nil;
            }
            if (blocksRemaining + blockNumber != totalBlocks) {
                //NSLog(@"Warning: Got blocks out of order: %ld, %d", blocksRemaining + blockNumber, totalBlocks);
            }
            //NSLog(@"Block: %lu, %d, %ld", data.length - 8, blocksRemaining, (long)blockNumber);
            [buffer replaceBytesInRange:NSMakeRange(CCNetworkUDPDataSize * blockNumber + 4,  data.length - 8) withBytes:(uint8_t *)data.bytes + 8];
            blocksRemaining--;
            break;
        }
        default:
            break;
    }
    
    if (blocksRemaining == 0) {
        static long frameNumber = 0;
        frameNumber++;
        totalDataSize = 0;
        return buffer;
    }
    return nil;
}

@end
