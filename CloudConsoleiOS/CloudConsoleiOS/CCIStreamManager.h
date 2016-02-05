//
//  CCIStreamManager.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CCUdpSocket.h"
#import "CCIStreamDecoder.h"

@protocol CCIStreamManagerDelegate <NSObject>

- (void)streamClosed;

@end

@interface CCIStreamManager : NSObject <CCUdpSocketDelegate>

@property (strong) CCUdpSocket  *streamSocket;
@property (assign, nonatomic) id <CCIStreamManagerDelegate> delegate;
@property (assign, nonatomic) id <CCIStreamDecoderDisplayDelegate> outputDelegate;

- (void)sendDirectionalState:(CGPoint)directionalState forJoy:(uint8_t)joyId;
- (void)sendButtonState:(uint32_t)buttonState;
- (void)closeStream;
@end
