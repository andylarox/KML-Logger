//
//  LogsViewController.m
//  GPSLogger
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import "LogsViewController.h"
#import "CoreDataStore.h"
#import "NSManagedObject+InnerBand.h"
#import "Track.h"
#import "MapViewController.h"

@interface LogsViewController ()
@property (strong, nonatomic) NSArray *tracks;
@end

@interface LogsViewController (UITableViewDataSource) <UITableViewDataSource>
@end

@interface LogsViewController (UITableViewDelegate) <UITableViewDelegate>
@end



@implementation LogsViewController

@synthesize tracks = __tracks;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSError *error;
    self.tracks = [[CoreDataStore mainStore] allForEntity:@"Track" orderBy:@"created" ascending:NO error:&error];
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
        
        Track *track = [self.tracks objectAtIndex:indexPath.row];

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
    
    Track *track = [self.tracks objectAtIndex:indexPath.row];
    
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
        Track *track = [self.tracks objectAtIndex:indexPath.row];
        
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.tracks];
        [array removeObject:track];
        self.tracks = [NSArray arrayWithArray:array];
        
        [track destroy];
        [[CoreDataStore mainStore] save];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
