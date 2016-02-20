//
//  ViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/8/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//
//  https://adoptioncurve.net/archives/2014/07/creating-a-draggable-uicollectionviewcell/ - Moving
//  http://goo.gl/k5WS2l -CCzip

#import "CCIMainViewController.h"

#import "AppDelegate.h"
#import "CCNetworkProtocol.h"
#import "CCIDevice.h"
#import <MRProgress/MRProgress.h>
#import "CCINewDeviceTableViewController.h"

#import <SystemConfiguration/CaptiveNetwork.h>


@interface CCIMainViewController () {
    
    IBOutlet UIBarButtonItem    *plusButton;
    IBOutlet UIBarButtonItem    *settingButton;
    
    CCINetworkController    *networkController;
    NSMutableArray          *connections;
    CCILanFinder            *deviceFinder;
    
    NSTimer                 *connectTimeout;
    NSTimer                 *pingTimer;
    CCISpotlight            *spotlight;
}

@end

@implementation CCIMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    self.navigationItem.title = @"Devices";
    
    [self.collectionView registerClass:[CCIDeviceCollectionViewCell class] forCellWithReuseIdentifier:@"DeviceCell"];
    self.collectionView.alwaysBounceVertical = YES;
    
    NSLog(@"Starting");
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat panelWidth = MIN(self.view.frame.size.width / 2 - 30, 180);
    NSInteger numPanels = self.view.frame.size.width/(panelWidth);
    CGFloat itemSpace = (self.view.frame.size.width - (panelWidth * numPanels))/3;
    [flowLayout setItemSize:CGSizeMake(panelWidth, 200)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    flowLayout.sectionInset = UIEdgeInsetsMake(15, itemSpace, 0, itemSpace);
    flowLayout.minimumInteritemSpacing = 15;
    flowLayout.minimumInteritemSpacing = itemSpace;
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    deviceFinder = [[CCILanFinder alloc] init];
    deviceFinder.delegate = self;
    
    spotlight = [CCISpotlight new];
    spotlight.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [deviceFinder start];
    AppDelegate.sharedInstance.networkController = nil;
    [self pingDevices];
    pingTimer = [NSTimer scheduledTimerWithTimeInterval:5  target:self selector:@selector(pingDevices) userInfo:nil repeats:YES];
    //[spotlight beginPresentation];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [deviceFinder stop];
    [pingTimer invalidate];
    [self cancelConnection];
}

#pragma mark - Spotlight
/*  Spotlight Delegate  */

- (void)CCISpotlight:(CCISpotlight *)aSpotlight showFrame:(NSInteger)frameNumber
{
    switch (frameNumber) {
        case 0: {
            CGPoint position = [self centerForBarButtonItem:plusButton];
            NSLog(@"%@", NSStringFromCGPoint(position));
            [aSpotlight showCircleSpotlightAtPoint:position radius:22];
            break;
        }
        case 1: {
            [aSpotlight showSquareSpotlightAtPoint:CGPointMake(self.view.frame.size.width/2, 22) size:CGSizeMake(100, 30)];
            break;
        }
        default:
            [aSpotlight endPresentation];
            break;
    }
}

- (CGPoint)centerForBarButtonItem:(UIBarButtonItem *)buttonItem
{
    UIView *view = [buttonItem valueForKey:@"view"];
    if (view){
        return [self.view convertPoint:view.center toView:nil];
        return view.center;
    }
    return CGPointZero;
}

#pragma mark - Networking
/*  Networking  */

- (void)pingDevices
{
    [deviceFinder.devices makeObjectsPerformSelector:@selector(pingDevice)];
}

- (void)connectedToServer
{
    [connectTimeout invalidate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"ToApps" sender:self];
    });
}

- (void)connectToDevice:(CCIDevice *)device
{
    AppDelegate.sharedInstance.networkController = [[CCINetworkController alloc] initWithHost:device.host port:device.port];
    AppDelegate.sharedInstance.networkController.delegate = self;
    
    [connectTimeout invalidate];
    connectTimeout = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(connectionTimedOut) userInfo:nil repeats:NO];
}

- (void)connectionTimedOut
{
    [AppDelegate.sharedInstance showWarning:@"Unable to connect to your computer." withTitle:@"Connection Timeout"];
    [self cancelConnection];
}

- (void)cancelConnection
{
    if (AppDelegate.sharedInstance.networkController.isConnected) {
        //Don't cancel because we're connected
        NSLog(@"Not cancelling");
        return;
    }
    [connectTimeout invalidate];
    NSLog(@"Cancel connect");
    AppDelegate.sharedInstance.networkController.delegate = nil;
    AppDelegate.sharedInstance.networkController = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        //Need to show connection error message!
        self.collectionView.userInteractionEnabled = YES;
        [self.collectionView reloadData];
    });
}

- (void)beginEditingDevice:(CCIDevice *)device
{
    UINavigationController *nav = (UINavigationController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CCINewDeviceNavigationController"];
    CCINewDeviceTableViewController *deviceEditor = [nav.viewControllers firstObject];
    deviceEditor.currentDevice = device;
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Device Finder Delegate

- (void)devicesFound
{
    [self.collectionView reloadData];
}

- (void)gotServiceDestination:(NSString *)host port:(uint16_t)port
{
    AppDelegate.sharedInstance.networkController = [[CCINetworkController alloc] initWithHost:host port:port];
    AppDelegate.sharedInstance.networkController.delegate = self;
    [self performSegueWithIdentifier:@"ToApps" sender:self];
}

#pragma mark - Collection Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return deviceFinder.devices.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CCIDevice *device = [deviceFinder.devices objectAtIndex:indexPath.row];
    CCIDeviceCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DeviceCell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.device = device;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        [deviceFinder stop];
        CCIDevice *device = [deviceFinder.devices objectAtIndex:indexPath.row];
        //Add to recents
        NSMutableDictionary *deviceDictionairy = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"Devices"] mutableCopy];
        if (!deviceDictionairy) {
            deviceDictionairy = [NSMutableDictionary new];
        }
        deviceDictionairy[device.name] = [NSKeyedArchiver archivedDataWithRootObject:device];
        [[NSUserDefaults standardUserDefaults] setObject:deviceDictionairy forKey:@"Devices"];
        [self connectToDevice:device];
    } else {
        NSNetService *service = [deviceFinder.services objectAtIndex:indexPath.row];
        [deviceFinder getServiceDestination:service];
    }
}


#pragma mark - Utility

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

-(BOOL)shouldAutorotate {
    return NO;
}

@end
