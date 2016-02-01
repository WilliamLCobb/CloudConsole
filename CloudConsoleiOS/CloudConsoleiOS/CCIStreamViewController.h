//
//  StreamViewController.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/11/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "CCIStreamManager.h"
#import "CCIControllerView.h"

@interface CCIStreamViewController : UIViewController <CCIStreamDecoderDisplayDelegate, CCIControllerViewDelegate>

@property (strong) CCIStreamManager   *streamManager;

- (void)closedStream;

@end
