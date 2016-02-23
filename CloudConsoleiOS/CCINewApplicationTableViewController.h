//
//  CCINewApplicationTableViewController.h
//  Cloud Console
//
//  Created by Will Cobb on 2/22/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CCINetworkController;
@interface CCINewApplicationTableViewController : UITableViewController

@property (weak)CCINetworkController    *networkController;

@end
