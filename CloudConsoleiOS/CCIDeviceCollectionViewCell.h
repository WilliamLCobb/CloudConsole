//
//  CCIDeviceCollectionViewCell.h
//  Cloud Console
//
//  Created by Will Cobb on 2/15/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CCIDevice;

@protocol CCIDeviceCollectionViewCellDelegate <NSObject>

- (void)cancelConnection;
- (void)beginEditingDevice:(CCIDevice *)device;

@end

@interface CCIDeviceCollectionViewCell : UICollectionViewCell

@property (weak) id                       delegate;
@property (nonatomic, strong) CCIDevice   *device;

@end
