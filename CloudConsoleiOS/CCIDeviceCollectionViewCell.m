//
//  CCIDeviceCollectionViewCell.m
//  Cloud Console
//
//  Created by Will Cobb on 2/15/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIDeviceCollectionViewCell.h"
#import "CCIDevice.h"
#import <MRProgress/MRProgress.h>
#import "AppDelegate.h"


@interface CCIDeviceCollectionViewCell () {
    /*  UI  */
    UIButton        *deviceEdit;
    UIImageView     *deviceDiscovery;
    UIImageView     *deviceImage;
    UILabel         *deviceName;
    
    MRActivityIndicatorView *activityView;
    MRCheckmarkIconView     *checkmarkView;
    MRCrossIconView         *crossView;
}

@end

@implementation CCIDeviceCollectionViewCell

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius = 3;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 3.0;
        self.backgroundColor = [UIColor whiteColor];
        
        /*  Edit  */
        deviceEdit = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        deviceEdit.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 19, 19);
        [deviceEdit setImage:[[UIImage imageNamed:@"gear12"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        deviceEdit.tintColor = [UIColor colorWithRed:71/255.0 green:73/255.0 blue:85/255.0 alpha:1];
        deviceEdit.alpha = 0.6;
        [self addSubview:deviceEdit];
        
        /*  Discovery Type  */
        deviceDiscovery = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width - 17, 5, 12, 12)];
        deviceDiscovery.alpha = 0.5;
        [self addSubview:deviceDiscovery];
        
        /*  Device Image  */
        CGFloat imageWidth = frame.size.width - 40;
        deviceImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, imageWidth, imageWidth/2)];
        [self addSubview:deviceImage];
        
        /*  Device Name  */
        deviceName = [[UILabel alloc] initWithFrame:CGRectMake(0, deviceImage.frame.size.height + 30, frame.size.width, 30)];
        deviceName.textAlignment = NSTextAlignmentCenter;
        [self addSubview:deviceName];
        
        /*  Availability image */
        CGRect availabilityImageRect = CGRectMake(frame.size.width/2 - 20, frame.size.height - 50, 40, 40);
        activityView = [[MRActivityIndicatorView alloc] initWithFrame:availabilityImageRect];
        activityView.hidden = YES;
        activityView.tintColor = kAppColor;
        [self addSubview:activityView];
        
        checkmarkView = [[MRCheckmarkIconView alloc] initWithFrame:availabilityImageRect];
        checkmarkView.hidden = YES;
        checkmarkView.tintColor = kAppColor;//[UIColor colorWithRed:0 green:222/255.0 blue:46/255.0 alpha:1];
        [self addSubview:checkmarkView];
        
        crossView = [[MRCrossIconView alloc] initWithFrame:availabilityImageRect];
        crossView.hidden = YES;
        crossView.tintColor = [UIColor colorWithRed:1 green:80/255.0 blue:53/255.0 alpha:1];
        [self addSubview:crossView];
    }
    return self;
}

- (void)setDevice:(CCIDevice *)device
{
    if (device == _device) {
        return;
    }
    
    if (_device) {
        [_device removeObserver:self forKeyPath:@"availability"];
    }
    _device = device;
    [device addObserver:self forKeyPath:@"availability" options:(NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew) context:nil];
    
    /*  Edit  */
    [deviceEdit removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [deviceEdit addTarget:self action:@selector(beginEditing) forControlEvents:UIControlEventTouchUpInside];
    
    /*  Discovery Type  */
    if (device.discoverType == CCIDeviceDiscoverTypeLAN) {
        deviceDiscovery.image = [[UIImage imageNamed:@"magnifying-glass"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        deviceDiscovery.tintColor = [UIColor colorWithRed:71/255.0 green:73/255.0 blue:85/255.0 alpha:1];
    } else if (device.discoverType == CCIDeviceDiscoverTypeFavorite) {
        deviceDiscovery.image = [[UIImage imageNamed:@"star"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        deviceDiscovery.tintColor = [UIColor colorWithRed:1 green:209/255.0 blue:75/255.0 alpha:1];
    } else if (device.discoverType == CCIDeviceDiscoverTypeGoogle) {
        deviceDiscovery.image = [[UIImage imageNamed:@"google"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        deviceDiscovery.tintColor = [UIColor colorWithRed:221/255.0 green:75/255.0 blue:57/255.0 alpha:1];
    }
    
    /*  Device Image  */
    if ([device.deviceName isEqualToString:@"mac"]) {
        deviceImage.image = [UIImage imageNamed:@"MBP.png"];
    } else {
        NSLog(@"Unknown Device type: %@", device.deviceName);
    }
    
    /*  Name  */
    deviceName.text = device.name;
    
    /*  Activity  */
    [self updateAvailability];
}

- (void)beginEditing
{
    [self.delegate beginEditingDevice:self.device];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        activityView.hidden = NO;
        checkmarkView.hidden = YES;
        crossView.hidden = YES;
        [activityView stopAnimating];
        [activityView performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:NO];
        activityView.mayStop = YES;
        
        // Remove all targets
        [activityView.stopButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [activityView.stopButton addTarget:self action:@selector(cancelConnection) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self updateAvailability];
    }
}

- (void)cancelConnection
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cancelConnection)]) {
        [self.delegate cancelConnection];
    }
}

- (void)updateAvailability
{
    if (self.selected) {
        return;
    }
    CCIDeviceavailability availability = self.device.availability;
    if (availability == CCIDeviceavailabilityUnknown) {
        activityView.hidden = NO;
        activityView.mayStop = NO;
        checkmarkView.hidden = YES;
        crossView.hidden = YES;
        [activityView stopAnimating];
        [activityView performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:NO];
    } else if (availability == CCIDeviceavailabilityAvaliable) {
        activityView.hidden = YES;
        checkmarkView.hidden = NO;
        crossView.hidden = YES;
    } else if (availability == CCIDeviceavailabilityNotAvaliable) {
        activityView.hidden = YES;
        checkmarkView.hidden = YES;
        crossView.hidden = NO;
    } else if (availability == CCIDeviceavailabilityInStream) {
        activityView.hidden = YES;
        checkmarkView.hidden = YES;
        crossView.hidden = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"availability"]) {
        [self updateAvailability];
    }
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)dealloc
{
    if (_device) {
        NSLog(@"Removing observer from %@", _device);
        [_device removeObserver:self forKeyPath:@"availability"];
    }
    
}

@end
