//
//  GATracker.h
//  Google Analytics Reports
//
//  Created by Zane Claes on 7/18/13.
//  Copyright (c) 2013 inZania LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GATracker : NSObject

@property (nonatomic, strong) NSString *deviceIdentifier;

- (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
                    withValue:(NSNumber *)value;

- (void)sendTimingWithCategory:(NSString *)category
                     withValue:(NSTimeInterval)time
                      withName:(NSString *)name
                     withLabel:(NSString *)label;

- (void)sendView:(NSString *)screen;
- (void)sendShutdown:(NSString*)category callback:(void (^)(NSError *err))block;
- (void)sendTransaction:(NSString*)transactionId affiliation:(NSString*)affiliation revenue:(NSNumber*)revenue;

- (id)initWithTrackingId:(NSString*)trackingId;

@end