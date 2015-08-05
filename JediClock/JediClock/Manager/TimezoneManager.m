//
//  TimezoneManager.m
//  JediClock
//
//  Created by Steven Masini on 8/5/15.
//  Copyright (c) 2015 Steven Masini. All rights reserved.
//

#import "TimezoneManager.h"
#import "Timezone.h"

@implementation TimezoneManager

#pragma mark - Singleton

+ (TimezoneManager *)sharedManager {
    static dispatch_once_t onceToken;
    static TimezoneManager *shared = nil;
    dispatch_once(&onceToken, ^{
        shared = [[TimezoneManager alloc] init];
    });
    return shared;
}

#pragma mark - NSObject inherited methods

- (instancetype)init {
    self = [super init];
    if (self) {
        self.context = [NSManagedObjectContext MR_defaultContext];
        [self setupTimezoneDatabase];
    }
    return self;
}

#pragma mark - TimezoneManager methods

- (void)setupTimezoneDatabase {
    if ([Timezone MR_countOfEntities] > 0) {
        return;
    }
    
    NSArray *identifiers = [NSTimeZone knownTimeZoneNames];
    for (NSString *identifier in identifiers) {
        [Timezone timezoneWithIdentifier:identifier inContext:self.context];
    }
    [self.context MR_saveToPersistentStoreAndWait];
}

- (NSArray *)fetchTimezones {    
    return [Timezone MR_findAll];;
}

@end
