//
//  CCIGameSelectionTableViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/27/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIGameSelectionTableViewController.h"
#import "AppDelegate.h"
#import "DALabeledCircularProgressView.h"

@interface CCIGameSelectionTableViewController () {
    CCINetworkController    *networkController;
    BOOL currentView;
    DALabeledCircularProgressView *progressView;
}

@end

@implementation CCIGameSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Set up loading text
    self.tableView.tableFooterView = [UIView new];
    self.tableView.tableFooterView.backgroundColor = [UIColor whiteColor];
    
    progressView = [[DALabeledCircularProgressView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 60, 10, 120, 120)];
    progressView.progressLabel.text = @"Loading...";
    progressView.progressTintColor = kAppColor;
    progressView.thicknessRatio = 0.11;
    progressView.roundedCorners = 5;
    [self.tableView.tableFooterView addSubview:progressView];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    if (!AppDelegate.sharedInstance.networkController.isConnected) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        networkController = AppDelegate.sharedInstance.networkController;
        [networkController registerProgressDelegate:self forBuffer:CCNetworkGetSubGames];
        [self.currentGame addObserver:self forKeyPath:@"subGames" options:NSKeyValueObservingOptionNew context:nil];
        [self.currentGame loadSubgames];
        networkController.delegate = self;
    }
    currentView = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    currentView = NO;
    [self.currentGame removeObserver:self forKeyPath:@"subGames"];
    networkController = nil;
}

- (void)downloadProgress:(float)progress forTag:(uint32_t)tag
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [progressView setProgress:progress animated:YES];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"subGames"]) {
        if (self.currentGame.subGames.count == 0) {
            [AppDelegate.sharedInstance showError:@"No games were found! " withTitle:@"No Games"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        });
    } else {
        NSLog(@"Unknown keypath: %@", keyPath);
    }
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.currentGame.subGames.count;
}

- (CCIGame *)gameForIndexPath:(NSIndexPath *)indexPath
{
    return self.currentGame.subGames[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"game"];
    
    CCIGame *game = [self gameForIndexPath:indexPath];
    if (game.icon) {
       cell.imageView.image = game.icon;
    }
    cell.textLabel.text = game.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    CCIGame *game = [self gameForIndexPath:indexPath];
    [AppDelegate.sharedInstance launchGame:game];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


