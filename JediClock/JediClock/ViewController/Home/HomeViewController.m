//
//  TimezoneTableViewController.m
//  JediClock
//
//  Created by Steven Masini on 8/3/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import "HomeViewController.h"
#import "ClockCell.h"
#import "TimezoneManager.h"

@interface HomeViewController () <UITableViewDataSource, UITabBarDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *timezones;
@end

@implementation HomeViewController

static NSString *clockCellIdentifier = @"ClockCell";

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"order > -1"];
    self.timezones = [[Timezone MR_findAllSortedBy:@"order" ascending:YES withPredicate:predicate] mutableCopy];
    for (Timezone *t in self.timezones) {
        NSLog(@"T: %@: %@", t.city, t.order);
    }
    NSLog(@"--------------------");
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.timezones.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ClockCell *cell = [tableView dequeueReusableCellWithIdentifier:clockCellIdentifier forIndexPath:indexPath];
    cell.showsReorderControl = YES;
    Timezone *timezone = self.timezones[indexPath.row];
    cell.timezone = timezone;
    NSLog(@"C: %@: %@", timezone.city, timezone.order);
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Timezone *timezone = self.timezones[indexPath.row];
        timezone.order = @(-1);
        [timezone.managedObjectContext MR_saveToPersistentStoreAndWait];
        
        [self.timezones removeObjectAtIndex:indexPath.row];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    Timezone *timezoneToMove = [self.timezones objectAtIndex:sourceIndexPath.row];
    [self.timezones removeObjectAtIndex:sourceIndexPath.row];
    [self.timezones insertObject:timezoneToMove atIndex:destinationIndexPath.row];
    timezoneToMove.order = @(destinationIndexPath.row + 1);
    [timezoneToMove.managedObjectContext MR_saveToPersistentStoreAndWait];
}

#pragma mark - IBAction

- (IBAction)editAction:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
}

@end
