GAReporting
===========

Google Analytics Reporting for OSX / Cocoa apps
There is an official library for iOS, but nothing for iOS.

Usage of this is extremely simple. First, create a tracker:
`GATracker *tracker = [[GATracker alloc] initWithTrackingId:@"YOUR_GA_PROFILE_ID"];`

Then just use the methods to track events, pageviews, etc.:
`[tracker sendEventWithCategory:@"category" withAction:@"action" withLabel:@"hello" withValue:@(0)];`

On shutdown, you can explicitly end the session, which will tell Google Analytics to terminate
the session duration for the given user.
`[tracker sendShutdown:@"shutdown" callback:nil];`

For advanced usage, consider overwriting `deviceIdentifier` with your own device ID.
For higher throughput, increase the max operations of `_ga_operation_queue`