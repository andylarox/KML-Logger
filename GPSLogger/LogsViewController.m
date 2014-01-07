//
//  LogsViewController.m
//  GPSLogger
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import "LogsViewController.h"
#import "MapViewController.h"
#import "IBCoreDataStore.h"
#import "NSManagedObject+InnerBand.h"
#import "Track.h"

@interface LogsViewController ()
@property (strong, nonatomic) NSArray *tracks;
@end

@interface LogsViewController (UITableViewDataSource) <UITableViewDataSource>
@end

@interface LogsViewController (UITableViewDelegate) <UITableViewDelegate>
@end

@implementation LogsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSError *error = nil;
    self.tracks = [[IBCoreDataStore mainStore] allForEntity:@"Track" orderBy:@"created" ascending:NO error:&error];
    if (error) {
        NSLog(@"%@", error);
    }

    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PushMapViewController"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        Track *track = self.tracks[indexPath.row];

        MapViewController *viewController = (MapViewController *)segue.destinationViewController;
        viewController.track = track;
    }
}

@end


#pragma mark - 
@implementation LogsViewController (UITableViewDataSource)

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tracks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Track *track = self.tracks[indexPath.row];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
    NSString *text = [formatter stringFromDate:track.created];
    
    cell.textLabel.text = text;

    return cell;
}

@end


#pragma mark -
@implementation LogsViewController (UITableViewDelegate)

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Track *track = self.tracks[indexPath.row];
        
        NSMutableArray *array = self.tracks.mutableCopy;
        [array removeObject:track];
        self.tracks = [NSArray arrayWithArray:array];
        
        [track destroy];
        [[IBCoreDataStore mainStore] save];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
