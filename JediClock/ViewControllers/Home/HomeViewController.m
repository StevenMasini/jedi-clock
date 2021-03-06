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
#import "UITableView+Jedi.h"

@interface HomeViewController () <UITableViewDataSource, UITableViewDelegate>
// gesture
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;

// views
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

// property
@property (strong, nonatomic) NSMutableArray *timezones;
@property (assign, nonatomic) BOOL shouldDisplayNumericClock;

// timer
// property
@property (assign, nonatomic) NSTimeInterval timeInterval;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation HomeViewController

static NSString *kWorldClockCellIdentifier    = @"ClockCell";
static NSString *kNoWorldClockCellIdentifier  = @"NoWorldClockCell";

#pragma mark - UIViewController inherited methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.editBarButtonItem setPossibleTitles:[NSSet setWithObjects:@"", @"Edit", @"Done", nil]];
    
    [self setupRefreshViewLoop];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"order > -1"];
    self.timezones = [[Timezone MR_findAllSortedBy:@"order" ascending:YES withPredicate:predicate] mutableCopy];
    self.tableView.scrollEnabled = self.timezones.count ? YES : NO;
    self.editBarButtonItem.title = self.timezones.count ? @"Edit" : @"";
    
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // reset
    self.editBarButtonItem.title = self.timezones.count ? @"Edit" : @"";
    self.tableView.editing = NO;
    self.tapGestureRecognizer.enabled = YES;
}

- (void)dealloc {
//    NSLog(@"♻️ Dealloc %@", NSStringFromClass([self class]));
}

#pragma mark - HomeViewController

- (void)setupRefreshViewLoop {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self
                                                selector:@selector(updateCells)
                                                userInfo:nil repeats:YES];
    [self.timer fire];
    
    // add the timer to the current run loop
    [NSRunLoop.currentRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)invalidateRefreshLoop {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateCells {
    if (self.timezones.count > 0) {
        NSArray *indexPaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in indexPaths) {
            ClockCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            Timezone *timezone = self.timezones[indexPath.row];
            
            [cell updateCellWithTimezone:timezone];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.timezones.count;
    } else {
        return self.timezones.count > 0 ? 0 : 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return tableView.rowHeight;
    }
    return tableView.jedi_allAvailableSpace;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        ClockCell *cell = [tableView dequeueReusableCellWithIdentifier:kWorldClockCellIdentifier
                                                          forIndexPath:indexPath];
        Timezone *timezone = self.timezones[indexPath.row];
        [cell updateCellWithTimezone:timezone];
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNoWorldClockCellIdentifier
                                                                forIndexPath:indexPath];
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Timezone *timezone = self.timezones[indexPath.row];
        timezone.order = @(-1);
        
        [self.timezones removeObjectAtIndex:indexPath.row];
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        // re-arrange the order for every object
        for (NSInteger i = 0; i < self.timezones.count; i++) {
            Timezone *t = self.timezones[i];
            t.order = @(i);
        }
        
        [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
        
        // avoid a crash if there is no more timezone to display
        if (self.timezones.count == 0) {
            NSIndexPath *noClockIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
            [self.tableView insertRowsAtIndexPaths:@[noClockIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            self.editBarButtonItem.title    = @"";
            self.tableView.editing          = NO;
            self.tableView.scrollEnabled    = NO;
        }
        [self.tableView endUpdates];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    Timezone *sourceTimezone        = [self.timezones objectAtIndex:sourceIndexPath.row];
    
    [self.timezones removeObjectAtIndex:sourceIndexPath.row];
    [self.timezones insertObject:sourceTimezone atIndex:destinationIndexPath.row];
    
    // re-arrange the order for every object
    for (NSInteger i = 0; i < self.timezones.count; i++) {
        Timezone *t = self.timezones[i];
        t.order = @(i);
    }
    
    [[NSManagedObjectContext MR_defaultContext] MR_saveToPersistentStoreAndWait];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1f;
}

#pragma mark - IBAction

- (IBAction)editAction:(UIBarButtonItem *)sender {
    if (self.timezones.count > 0) {
        [self.tableView setEditing:!self.tableView.editing animated:YES];
        sender.title = self.tableView.editing ? @"Done" : @"Edit";
        self.tapGestureRecognizer.enabled = !self.tableView.editing;
    }
}

- (IBAction)tapGestureAction:(id)sender {
    if (self.timezones.count > 0) {
        self.shouldDisplayNumericClock = !self.shouldDisplayNumericClock;
        
        for (NSUInteger i = 0; i < self.tableView.numberOfSections; i++) {
            for (NSUInteger j = 0; j < [self.tableView numberOfRowsInSection:i]; j++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
                ClockCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                cell.clockDisplay = !cell.clockDisplay;
            }
        }
    }
}

@end
