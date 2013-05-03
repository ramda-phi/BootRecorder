//
//  RSView.m
//  BootRecorder
//
//  Created by JO Hiroshi on 5/2/13.
//  Copyright (c) 2013 joh. All rights reserved.
//

#import "RSView.h"
#import "BootRecorderAppDelegate.h"
#import "Log.h"

@implementation RSView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
//    NSLog(@"width = %f / height = %f", bounds.size.width, bounds.size.height);
//    [[NSColor darkGrayColor] set];
//    [NSBezierPath fillRect:bounds];
    
    [[NSColor colorWithDeviceWhite:0 alpha:0.5] set];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
    
    NSLog(@"");
    
    // cf. http://blog.guttyo.jp/?p=1187
    BOOL isDataRead = [[NSApp delegate] isDataRead];
    NSManagedObjectContext *moc = [[NSApp delegate] managedObjectContext];
    //    NSLog(@"%d", dataCount);

    if (!isDataRead) return;
    
    NSRect drawBounds;
    drawBounds.origin.x = bounds.origin.x + bounds.size.width / 20;
    drawBounds.origin.y = bounds.origin.y + bounds.size.height / 20;
    drawBounds.size.width = bounds.size.width - bounds.size.width / 10;
    drawBounds.size.height = bounds.size.height - bounds.size.height / 10;
    
//    [[NSColor greenColor] set];
//    [NSBezierPath fillRect:drawBounds];
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:1.0];
    NSPoint bp = NSPointFromCGPoint(drawBounds.origin);
    [path moveToPoint:bp];
    NSPoint ep = NSPointFromCGPoint(CGPointMake(drawBounds.origin.x + drawBounds.size.width, drawBounds.origin.y));
    [path lineToPoint:ep];
    [path closePath];
    [[NSColor whiteColor] set];
    [path stroke];
    
    
    
    NSMutableArray *arrayHour = [self arrangeData:moc :@"dTimeWaking" :NO];
    Log *log = [arrayHour objectAtIndex:0];
    double maxHour = [[log valueForKey:@"dTimeWaking"] doubleValue];
//    NSLog(@"%f", maxHour);
    
    NSMutableArray *orderedArray = [self arrangeData:moc :@"order" :NO];
    [self strokeBarChart:drawBounds :orderedArray :maxHour];
    
    [self setNeedsDisplay:YES];
    
}

// Return NSPoint projected to bounds
- (NSPoint)ProjectedPoint :(float)px : (float)py :(NSRect)projectedBounds
{
    NSPoint point;
    
    return point;
}

// Draw Bar-chart
- (void)strokeBarChart :(NSRect)bounds :(NSMutableArray*)orderdArray :(double)yMax
{
    BOOL isDataRead = [[NSApp delegate] isDataRead];
    if (!isDataRead) return;
    
    int dataCount = (int)orderdArray.count;
    
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path setLineWidth:2.0];

    [[NSColor purpleColor] set];

    for (int i = 0; i < dataCount; i += 1)
    {
        Log *log = [orderdArray objectAtIndex:i];
        double hour = [[log valueForKey:@"dTimeWaking"] doubleValue];
        double x = bounds.origin.x + (bounds.size.width / dataCount) * i;
        double y = bounds.origin.y + (bounds.size.height / yMax) * hour;
        
        NSPoint bp = NSPointFromCGPoint(CGPointMake(x, bounds.origin.y));
        NSPoint ep = NSPointFromCGPoint(CGPointMake(x, y));

        [path moveToPoint:bp];
        [path lineToPoint:ep];
        [path closePath];
        [path stroke];
    }
}

// Return Sorted data
- (NSMutableArray *)arrangeData :(NSManagedObjectContext *)managedObjectContext :(NSString *)keyName :(BOOL)ascending
{
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
    
    // Set Entity
    NSEntityDescription * entity = [NSEntityDescription entityForName:@"Log"
                                               inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    // Sort in order
    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:keyName ascending:ascending];
    NSArray * sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError * error = nil;
    NSMutableArray * mutableFetchResults = [[managedObjectContext
                                             executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if (mutableFetchResults == nil) {
        NSLog(@"sort error: %@", error);
    }
    
    return mutableFetchResults;
}

@end
