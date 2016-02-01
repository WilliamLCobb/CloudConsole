//
//  CCIGameSelectionTableViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/27/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIGameSelectionTableViewController.h"
#import "AppDelegate.h"
#import "CCIStreamViewController.h"
@interface CCIGameSelectionTableViewController ()

@end

@implementation CCIGameSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.currentGame addObserver:self forKeyPath:@"subGames" options:NSKeyValueObservingOptionNew context:nil];
    [self.currentGame loadSubgames];
    self.tableView.tableFooterView = [UIView new];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"subGames"]) {
        [self.tableView reloadData];
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
    //cell.imageView.image = game.icon;
    cell.textLabel.text = game.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    CCIGame *game = [self gameForIndexPath:indexPath];
    
    CCIStreamManager *streamManager = [AppDelegate.sharedInstance.networkController startStreamWithGame:game];
    CCIStreamViewController *streamViewController = (CCIStreamViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CCIStreamViewController"];
    streamViewController.streamManager = streamManager;
    
    streamManager.outputDelegate = streamViewController;
    [self presentViewController:streamViewController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self.currentGame removeObserver:self forKeyPath:@"subGames"];
}

@end
