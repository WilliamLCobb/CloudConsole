//
//  CCIGameSelectionTableViewController.m
//  CloudConsoleiOS
//
//  Created by Will Cobb on 1/23/16.
//  Copyright © 2016 Will Cobb. All rights reserved.
//

#import "CCIAppSelectionTableViewController.h"

#import "AppDelegate.h"
#import "CCINetworkController.h"
#import "CCIStreamViewController.h"
#import "CCIGame.h"

#import "CCIGameSelectionTableViewController.h"

@interface CCIAppSelectionTableViewController () {
    CCIGame                 *selectedGame;
    CCINetworkController    *networkController;
}

@end

@implementation CCIAppSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    networkController = AppDelegate.sharedInstance.networkController;
    
    NSLog(@"%@", networkController);
    
    [networkController addObserver:self forKeyPath:@"games" options:NSKeyValueObservingOptionNew context:nil];
    
    [networkController updateAvaliableGames];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"games"]) {
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
    return networkController.games.count;
}

- (CCIGame *)gameForIndexPath:(NSIndexPath *)indexPath
{
    return networkController.games[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"game"];
    
    CCIGame *game = [self gameForIndexPath:indexPath];
    cell.imageView.image = game.icon;
    cell.textLabel.text = game.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    CCIGame *game = [self gameForIndexPath:indexPath];
    if (game.hasTable) {
        selectedGame = game;
        [self performSegueWithIdentifier:@"ToGames" sender:self];
    } else {
        CCIStreamManager *streamManager = [networkController startStreamWithGame:game];
        CCIStreamViewController *streamViewController = (CCIStreamViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CCIStreamViewController"];
        streamViewController.streamManager = streamManager;
        
        streamManager.outputDelegate = streamViewController;
        [self presentViewController:streamViewController animated:YES completion:nil];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [networkController removeObserver:self forKeyPath:@"games"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ToGames"]) {
        CCIGameSelectionTableViewController *destination = segue.destinationViewController;
        destination.currentGame = selectedGame;
    }
}

@end
