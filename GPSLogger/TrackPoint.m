//
//  TrackPoint.m
//  GPSLogger
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import "TrackPoint.h"
#import "Track.h"


@implementation TrackPoint

@dynamic longitude;
@dynamic latitude;
@dynamic created;
@dynamic altitude;
@dynamic track;


- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.latitude.floatValue, self.longitude.floatValue);
}

@end
