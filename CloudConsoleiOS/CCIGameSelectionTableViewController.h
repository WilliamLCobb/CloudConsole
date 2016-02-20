//
//  CCIGameSelectionTableViewController.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/27/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCIGame.h"
#import "CCINetworkController.h"
@interface CCIGameSelectionTableViewController : UITableViewController <CCINetworkControllerDelegate>

@property CCIGame *currentGame;

@end
