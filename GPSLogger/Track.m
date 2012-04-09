//
//  Track.m
//  GPSLogger
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import "Track.h"
#import "TrackPoint.h"


@implementation Track

@dynamic created;
@dynamic trackpoints;


- (NSArray *)sotredTrackPoints
{
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:YES];
    return [self.trackpoints sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
}

@end
