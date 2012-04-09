//
//  Track.h
//  GPSLogger
//
//  Created by NextBusinessSystem on 12/01/26.
//  Copyright (c) 2012 NextBusinessSystem Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TrackPoint;

@interface Track : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSSet *trackpoints;

- (NSArray *)sotredTrackPoints;

@end

@interface Track (CoreDataGeneratedAccessors)

- (void)addTrackpointsObject:(TrackPoint *)value;
- (void)removeTrackpointsObject:(TrackPoint *)value;
- (void)addTrackpoints:(NSSet *)values;
- (void)removeTrackpoints:(NSSet *)values;

@end
