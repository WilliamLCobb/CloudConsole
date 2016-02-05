//
//  ViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIMainViewController.h"

#import "AppDelegate.h"
#import "CCINetworkController.h"
#import "CCNetworkProtocol.h"
#import "CCIDevice.h"

#import <SystemConfiguration/CaptiveNetwork.h>

@interface CCIMainViewController () {
    CCINetworkController    *networkController;
    NSMutableArray          *connections;
    CCILanFinder            *deviceFinder;
}

@end

@implementation CCIMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    networkController = AppDelegate.sharedInstance.networkController;
    
    NSLog(@"Starting");
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    UILabel *searchingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, self.view.frame.size.width - 40, 20)];
    searchingLabel.text = [NSString stringWithFormat:@"Searching for devices %@", [self currentWifiSSID]];
    searchingLabel.textAlignment = NSTextAlignmentCenter;
    searchingLabel.numberOfLines = 0;
    [searchingLabel sizeToFit];
    searchingLabel.center = CGPointMake(self.view.center.x, searchingLabel.center.y);
    [self.tableView.tableFooterView addSubview:searchingLabel];
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activity startAnimating];
    activity.frame = CGRectMake(self.view.frame.size.width/2 - activity.frame.size.width/2, searchingLabel.frame.size.height + 20, activity.frame.size.width, activity.frame.size.height);
    [self.tableView.tableFooterView addSubview:activity];
    
    deviceFinder = [[CCILanFinder alloc] init];
    deviceFinder.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [deviceFinder start];
}

#pragma mark - Device Finder Delegate

- (void)devicesFound
{
    [self.tableView reloadData];
}

- (void)gotServiceDestination:(NSString *)host port:(uint16_t)port
{
    AppDelegate.sharedInstance.networkController = [[CCINetworkController alloc] initWithHost:host port:port];
    [self performSegueWithIdentifier:@"ToApps" sender:self];
}

#pragma mark - Table Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return deviceFinder.devices.count;
    else
        return deviceFinder.services.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *name;
    if (indexPath.section == 0) {
        CCIDevice *device = [deviceFinder.devices objectAtIndex:indexPath.row];
        name = [NSString stringWithFormat:@"%@(*)", device.name];
    } else {
        NSNetService *service = [deviceFinder.services objectAtIndex:indexPath.row];
        name = service.name;
    }
    
    //UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"server"];
    NSArray *components = [name componentsSeparatedByString:@"."];
    NSLog(@"Name..: %@", name);
    NSString *device = components[0];
    cell.textLabel.text = components[1];
    cell.textLabel.numberOfLines = 0;
    
    if ([device isEqualToString:@"mac"]) {
        cell.imageView.image = [self imageWithImage:[UIImage imageNamed:@"MBP.png"] scaledToSize:CGSizeMake(100, 50)];
    } else {
        NSLog(@"Error, unknown device");
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [deviceFinder stop];
        CCIDevice *device = [deviceFinder.devices objectAtIndex:indexPath.row];
        AppDelegate.sharedInstance.networkController = [[CCINetworkController alloc] initWithHost:device.host port:device.port];
        [self performSegueWithIdentifier:@"ToApps" sender:self];
    } else {
        NSNetService *service = [deviceFinder.services objectAtIndex:indexPath.row];
        [deviceFinder getServiceDestination:service];
        //Show connecting indicator
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

- (NSString *)currentWifiSSID {
    // Does not work on the simulator.
    NSString *ssid = nil;
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info[@"SSID"]) {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
