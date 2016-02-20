//
//  ViewController.h
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCILanFinder.h"
#import "CCINetworkController.h"
#import "CCIDeviceCollectionViewCell.h"
#import "CCISpotlight.h"
@interface CCIMainViewController : UICollectionViewController <CCILanDelegate, CCINetworkControllerDelegate, UICollectionViewDelegateFlowLayout, CCIDeviceCollectionViewCellDelegate, CCISpotlightDelegate>

@end

