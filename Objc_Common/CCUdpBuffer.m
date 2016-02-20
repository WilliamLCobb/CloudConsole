//
//  CCUdpBuffer.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/23/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCUdpBuffer.h"
#import "CCUdpSocket.h"
@interface CCUdpBuffer () {
    //Receiving
    NSMutableData   *buffer;
    uint32_t        totalReceivingDataSize;
    uint32_t        totalReceivingBlocks;
    uint32_t        blocksReceivingRemaining;
    uint32_t        lastReceivingBlock;
    
    //Sending
    BOOL            sending;
    NSMutableArray  *sendQueue;
    dispatch_semaphore_t acknowledgeSem;
    uint32_t        currentSendingBlock;
}

@end

@implementation CCUdpBuffer

-(id)initWithTag:(uint32_t)tag delegate:(id <CCUdpBufferDelegate>)delegate
{
    if (self = [super init]) {
        self.tag = tag;
        self.delegate = delegate;
        sendQueue = [NSMutableArray new];
        acknowledgeSem = dispatch_semaphore_create(0);
    }
    return self;
}

#pragma mark - Sending

- (void)queueDataForSending:(NSData *)data withMethod:(CCUdpSendMethod)method
{
    [sendQueue addObject:@[[NSNumber numberWithInteger:method], data]];
    [self beginSending];
}

- (void)beginSending
{
    if (sending) {
        return;
    }
    sending = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (sendQueue.count > 0) {
            NSArray         *sendParameters = sendQueue[0];
            CCUdpSendMethod method = [sendParameters[0] integerValue];
            NSData          *data = sendParameters[1];
            if (method == CCUdpSendMethodStream) {
                [self streamSendData:data];
            } else if (method == CCUdpSendMethodGuarentee) {
                [self guarenteeSendData:data];
            } else if (method == CCUdpSendMethodRedundent) {
                [self streamSendData:data];
            } else {
                ERROR_LOG(@"Incorrect send method: %ld", method);
            }
            [sendQueue removeObjectAtIndex:0];
        }
        sending = NO;
    });
}

- (void)streamSendData:(NSData *)data
{
    currentSendingBlock = 0;
    NSUInteger length = data.length;
    NSUInteger offset = 0;
    
    NSMutableData * chunk;
    do {
        NSUInteger thisChunkSize = length - offset > CCNetworkUDPDataSize ? CCNetworkUDPDataSize : length - offset;
        if (currentSendingBlock == 0) {
            uint32_t header[3] = {self.tag, CCNetworkStreamBeginBlock, (uint32_t)length};
            chunk = [[NSMutableData alloc] initWithLength:thisChunkSize + 12];
            [chunk replaceBytesInRange:NSMakeRange(0, 12) withBytes:header];
        } else {
            uint32_t header[3] = {self.tag, CCNetworkStreamBlockNumber, currentSendingBlock};
            chunk = [[NSMutableData alloc] initWithLength:thisChunkSize + 12];
            [chunk replaceBytesInRange:NSMakeRange(0, 12) withBytes:header];
        }
        [chunk replaceBytesInRange:NSMakeRange(12, thisChunkSize) withBytes:data.bytes + offset];
        offset += thisChunkSize;
        [self.delegate sendData:chunk];
        currentSendingBlock++;
    } while (offset < length && [self.delegate connected]);
}

- (void)guarenteeSendData:(NSData *)data
{
    currentSendingBlock = 0;
    uint32_t lastSentBlock = 0;
    NSUInteger length = data.length;
    NSUInteger offset = 0;
    NSInteger errorNumber = 0;
    
    NSMutableData * chunk;
    do {
        // Could use this to give up on sending
//        if (lastSentBlock == currentSendingBlock) {
//            errorNumber++;
//            if (errorNumber > 5) {
//                
//            }
//        } else {
//            lastSentBlock++;
//            errorNumber = 0;
//        }
        
        NSUInteger thisChunkSize = length - offset > CCNetworkUDPDataSize ? CCNetworkUDPDataSize : length - offset;
        
        
        if (currentSendingBlock == 0) {
            uint32_t header[4] = {self.tag, CCNetworkStreamAcknowledge, CCNetworkStreamBeginBlock, (uint32_t)length};
            chunk = [[NSMutableData alloc] initWithLength:thisChunkSize + 16];
            [chunk replaceBytesInRange:NSMakeRange(0, 16) withBytes:header];
        } else {
            uint32_t header[4] = {self.tag, CCNetworkStreamAcknowledge, CCNetworkStreamBlockNumber, currentSendingBlock};
            chunk = [[NSMutableData alloc] initWithLength:thisChunkSize + 16];
            [chunk replaceBytesInRange:NSMakeRange(0, 16) withBytes:header];
        }
        [chunk replaceBytesInRange:NSMakeRange(16, thisChunkSize) withBytes:data.bytes + offset];
        [self.delegate sendData:chunk];
        dispatch_semaphore_wait(acknowledgeSem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)));
        offset = currentSendingBlock * CCNetworkUDPDataSize;
        //Our receiver will increment the block number
    } while (offset < length  && [self.delegate connected]);
}

#pragma mark - Receiving

- (NSData *)consumeData:(NSData *)data
{
    uint32_t *message = (uint32_t *)data.bytes;
    switch (message[0]) {
        case CCNetworkStreamAcknowledged: {
            uint32_t receivedBlock = message[1];
            // They got the block, increment the current block number and unlock the sender
            if (receivedBlock == currentSendingBlock) {
                currentSendingBlock++;
                dispatch_semaphore_signal(acknowledgeSem);
            }
            return nil;
        }

        case CCNetworkStreamAcknowledge: { //asking us to acknowledge that we got it
            uint32_t receivedBlock;
            uint32_t blockType = message[1];
            if (blockType == CCNetworkStreamBeginBlock) {
                receivedBlock = 0;
            } else {
                receivedBlock = message[2];
            }
            uint32_t returnData[3] = {self.tag, CCNetworkStreamAcknowledged, receivedBlock};
            [self.delegate sendData:[NSData dataWithBytes:&returnData length:12]];
            
            //consome again w/o acknowledge tag
            return [self consumeData:[NSData dataWithBytesNoCopy:(void *)data.bytes+4 length:data.length-4 freeWhenDone:NO]];
        }
        case CCNetworkStreamBeginBlock:
            if (blocksReceivingRemaining != 0) {
                NSLog(@"Lost %d blocks of data", blocksReceivingRemaining);
            }
            lastReceivingBlock = 0;
            totalReceivingDataSize = message[1];
            blocksReceivingRemaining = totalReceivingDataSize/CCNetworkUDPDataSize + 1;
            totalReceivingBlocks = blocksReceivingRemaining;
            
            
            //NSLog(@"Begin: %lu, %d, %ld", data.length - 12, blocksRemaining, (long)totalDataSize);
            if (blocksReceivingRemaining == 1) { //Single Packet
                buffer = [NSMutableData dataWithBytes:(uint8_t *)data.bytes + 8 length:totalReceivingDataSize];
            } else {
                buffer = [NSMutableData dataWithLength:totalReceivingDataSize];
                [buffer replaceBytesInRange:NSMakeRange(0, CCNetworkUDPDataSize)
                                  withBytes:(uint8_t *)data.bytes + 8 length:CCNetworkUDPDataSize];
            }
            blocksReceivingRemaining--;
            break;
            
        case CCNetworkStreamBlockNumber:
        {
            if (totalReceivingDataSize == 0) {
                NSLog(@"Warning: Got a block before a begin!");
                return nil;
            }
            uint32_t blockNumber = message[1];
            if (CCNetworkUDPDataSize * blockNumber + data.length-12 > buffer.length) {
                NSLog(@"Error, tried to write outside buffer. %ld, %ld", CCNetworkUDPDataSize * blockNumber + data.length-12, buffer.length);
                //return nil;
            }
            if (blockNumber != lastReceivingBlock + 1) {
                NSLog(@"Warning: Got blocks out of order: %u %u", lastReceivingBlock, blockNumber);
                return nil;
            }
            //NSLog(@"Block: %lu, %d, %ld, %@", data.length - 8, blocksReceivingRemaining, (long)blockNumber, [NSThread currentThread]);
            [buffer replaceBytesInRange:NSMakeRange(CCNetworkUDPDataSize * blockNumber,  data.length - 8) withBytes:(uint8_t *)data.bytes + 8];
            blocksReceivingRemaining--;
            lastReceivingBlock = blockNumber;
            break;
        }
        default:
            NSLog(@"Error, no tag!");
            break;
    }
    
    [self notifyProgress:((totalReceivingBlocks - blocksReceivingRemaining) / (float)totalReceivingBlocks)];
    
    if (blocksReceivingRemaining == 0) {
        totalReceivingDataSize = 0;
        return buffer;
    }
    return nil;
}

- (void)notifyProgress:(float)progress
{
    if ([self.delegate respondsToSelector:@selector(receiveProgress:forTag:)]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self.delegate receiveProgress:progress forTag:self.tag];
        });
    }
}

@end
