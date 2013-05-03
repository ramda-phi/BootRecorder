//
//  Log.h
//  BootRecorder
//
//  Created by JO Hiroshi on 4/30/13.
//  Copyright (c) 2013 joh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Log : NSManagedObject

@property (nonatomic, retain) NSNumber * dTimeWaking;
@property (nonatomic, retain) NSString * sPeriod;
@property (nonatomic, retain) NSDate * sReboot;
@property (nonatomic, retain) NSDate * sShutDown;
@property (nonatomic, retain) NSString * sTimeWaking;
@property (nonatomic, retain) NSNumber * order;

@end
