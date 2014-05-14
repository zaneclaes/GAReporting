//
//  GATracker.m
//  Google Analytics Reports
//
//  Created by Zane Claes on 7/18/13.
//  Copyright (c) 2013 inZania LLC. All rights reserved.
//

#import "GATracker.h"

#define URL_GA    @"https://ssl.google-analytics.com/collect?payload_data"
#define DEBUG_GA  YES

//
// Helper methods for building URLs
//
@implementation NSString (URLEncoding)

- (NSString*)urlEscapeString {
  CFStringRef originalStringRef = (__bridge_retained CFStringRef)self;
  NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
  CFRelease(originalStringRef);
  return s;
}

- (NSString*)addQueryStringToUrlStringWithDictionary:(NSDictionary *)dictionary {
  NSMutableString *urlWithQuerystring = [[NSMutableString alloc] initWithString:self];

  for (id key in dictionary) {
    NSString *keyString = [key description];
    NSString *valueString = [[dictionary objectForKey:key] description];

    if ([urlWithQuerystring rangeOfString:@"?"].location == NSNotFound) {
      [urlWithQuerystring appendFormat:@"?%@=%@", [keyString urlEscapeString], [valueString urlEscapeString]];
    } else {
      [urlWithQuerystring appendFormat:@"&%@=%@", [keyString urlEscapeString], [valueString urlEscapeString]];
    }
  }
  return urlWithQuerystring;
}

@end

//
// Main reporting class
//
@interface GATracker ()
@property (nonatomic, strong) NSString *trackingId;
@property (nonatomic, readwrite) BOOL hasSent;
@end


@implementation GATracker

- (NSString *)deviceIdentifier {
  if(!_deviceIdentifier.length) {
    static NSString     *name    = @"device_udid";
    NSUserDefaults  *defaults = [NSUserDefaults standardUserDefaults];
    NSString *value = [defaults objectForKey: name];

    if (!value) {
      value = (NSString *) CFBridgingRelease(CFUUIDCreateString (NULL, CFUUIDCreate(NULL)));
      [defaults setObject: value forKey: name];
      [defaults synchronize];
    }
    _deviceIdentifier = value;
  }
  return _deviceIdentifier;
}

- (id)initWithTrackingId:(NSString*)trackingId {
  if ((self = [super init])) {
    self.trackingId = trackingId;
  }
  return self;
}

- (void)send:(NSString*)verb params:(NSDictionary*)p callback:(void (^)(NSError *err))cb {
  CGSize size = [NSScreen mainScreen].frame.size;
  NSMutableDictionary *params = [p?:@{} mutableCopy];
  params[@"v"] = @(1);
  params[@"tid"] = self.trackingId;
  params[@"cid"] = self.deviceIdentifier;
  params[@"vp"] = [NSString stringWithFormat:@"%dx%d",(int)size.width,(int)size.height];
  params[@"ul"] = [[NSLocale preferredLanguages] firstObject];
  params[@"t"] = verb;
  if(!self.hasSent) {
    params[@"sc"] = @"start";
    self.hasSent = YES;
  }
  params[@"z"] = @(time(nil));// Cache buster
  NSString *url = [URL_GA addQueryStringToUrlStringWithDictionary:params];

  //
  // Use an operation queue for sending up the tracking event
  //
  static NSOperationQueue *_ga_operation_queue = nil;
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    _ga_operation_queue = [[NSOperationQueue alloc] init];
    [_ga_operation_queue setMaxConcurrentOperationCount:1];
  });
  [_ga_operation_queue addOperationWithBlock:^{
    NSError *err = nil;
    NSData *res = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    if(DEBUG_GA) {
      NSLog(@"GAN[%@][%@] => %@",err,url,[[NSString alloc] initWithData:res encoding:NSASCIIStringEncoding]);
    }
    if(cb) {
      cb(err);
    }
  }];
}

- (void)sendTransaction:(NSString*)transactionId affiliation:(NSString*)affiliation revenue:(NSNumber*)revenue {
  return [self send:@"transaction" params:@{@"ti":transactionId,@"ta":affiliation?:@"",@"tr":revenue?:@(0)} callback:nil];
}

- (void)sendTimingWithCategory:(NSString *)category
                     withValue:(NSTimeInterval)time
                      withName:(NSString *)name
                     withLabel:(NSString *)label {
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"utc"] = category;
  params[@"utv"] = name;
  if(label) {
    params[@"utl"] = label;
  }
  params[@"utt"] = @(time);
  return [self send:@"timing" params:params callback:nil];
}

- (void)sendShutdown:(NSString*)category callback:(void (^)(NSError *err))cb {
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"ec"] = category;
  params[@"sc"] = @"end";
  return [self send:@"event" params:params callback:cb];
}

- (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
                    withValue:(NSNumber *)value {
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  params[@"ec"] = category;
  params[@"ea"] = action;
  if(label) {
    params[@"el"] = label;
  }
  if(value) {
    params[@"ev"] = value;
  }
  return [self send:@"event" params:params callback:nil];
}


- (void)sendView:(NSString *)page {
  return [self send:@"pageview" params:@{@"dp":page} callback:nil];
}

@end