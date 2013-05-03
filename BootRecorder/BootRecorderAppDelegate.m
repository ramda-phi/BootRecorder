//
//  BootRecorderAppDelegate.m
//  BootRecorder
//
//  Created by JO Hiroshi on 4/28/13.
//  Copyright (c) 2013 joh. All rights reserved.
//

#import "BootRecorderAppDelegate.h"
#import "Log.h"
#import "RSView.h"


#ifdef DEBUG
void uncaughtExceptionHandler(NSException *exception)
{
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
    // Internal error reporting
}
#endif


@implementation BootRecorderAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize isDataRead = _isDataRead;
@synthesize dataCount = _dataCount;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    #ifdef DEBUG
    // Set unhandled error 
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    #endif
    
    _isDataRead = false;
    
//    [self.window setTitle:@""];
    
    // Set ManagedObjectContext
    [arrayController setManagedObjectContext:_managedObjectContext];
    
    [self readLogs];
    _isDataRead = true;

    [tableView reloadData];
    [self arrangeList];
    
//    RSView *view;
//    [view setNeedsDisplay:YES];
}

- (void)awakeFromNib
{
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "joh.BootRecorder" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"joh.BootRecorder"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BootRecorder" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"BootRecorder.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)initFrame:(id)sender
{
    NSSize size = NSMakeSize(480, 360);
    [self.window setContentSize:size];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (void)errMsg :(NSString*)message
{
    NSLog(@"%@", message);
    NSInteger i = NSRunAlertPanel(@"Error",
                                  message,
                                  @"OK",
                                  nil,
                                  nil);
    NSLog(@"%ld", i);
}

// tmp: delete log
- (void)deleteLogs
{
    NSFetchRequest* requestDelete = [[NSFetchRequest alloc] init];
    [requestDelete setEntity:[NSEntityDescription entityForName:@"Log" inManagedObjectContext:_managedObjectContext]];
    [requestDelete setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError * error = nil;
    NSArray * dataArray = [_managedObjectContext executeFetchRequest:requestDelete error:&error];
    //error handling goes here
    for (NSManagedObject * data in dataArray) {
        [_managedObjectContext deleteObject:data];
    }
    NSError *saveError = nil;
    [_managedObjectContext save:&saveError];
}

// Use 'shell command' and return output log
- (NSString*)launchCommand:(NSArray*)_args
{
    // Create Task Object
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    [task setArguments:_args];

    // Create pipe
    NSPipe *outPipe = [[NSPipe alloc] init];
    [task setStandardOutput: outPipe];
    
    // Run process
    [task launch];
    
    // Read Output
    NSData *_data = [[outPipe fileHandleForReading] readDataToEndOfFile];
    
    // Check end of process
    [task waitUntilExit];
    int status = [task terminationStatus];
    if (status != 0)
    {
        NSString *msg = [NSString stringWithFormat:@"Err in launch command : %d", status];
        [self errMsg:msg];
        
        return NO;
    }
    
    // Convert to string
    NSString *_log = [[NSString alloc]
                          initWithData:_data encoding:NSUTF8StringEncoding];

    return _log;
}

// 
- (BOOL)readLogs
{
    int i;
    NSString *pattern;
    NSError *err = nil;
    NSDateFormatter *formatter;

    // Set date format
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    // Launch 'uptime' command
    NSArray * uptime_args = [NSArray arrayWithObjects:@"-c", @"uptime | cut -d',' -f1 | sed 's/^.*up *//'", nil];
    NSString * uptime = [self launchCommand: uptime_args];
    NSLog(@"uptime = %@", uptime);
    NSArray * arrayUptime = [uptime componentsSeparatedByString:@":"];
    
    // Calculate the time launched
    NSDate * dateLaunch;
    if (arrayUptime.count == 2)
        dateLaunch = [NSDate dateWithTimeIntervalSinceNow:-([arrayUptime[0] intValue] * 60 * 60 + [arrayUptime[1] intValue] * 60)];
    else if (arrayUptime.count == 1) // lower than 1 hour
    {
        NSArray * minArray = [uptime componentsSeparatedByString:@" "];
        dateLaunch = [NSDate dateWithTimeIntervalSinceNow:-[minArray[0] intValue] * 60];
    }
    NSLog(@"launch_str = %@", [formatter stringFromDate:dateLaunch]);
    
    // Compare launch time
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    NSString * strSaved = [ud objectForKey:@"LAUNCH_DATE"];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];

    if ([strSaved isEqualToString:[formatter stringFromDate:dateLaunch]])
    {
        [self arrangeList];
        
        // Update the first index
        // 
        
//        return YES;
    }
    NSLog(@"strSaved = %@", strSaved);
    [ud setObject:[formatter stringFromDate:dateLaunch] forKey:@"LAUNCH_DATE"];
    
    // tmp: Delete data
    [self deleteLogs];
    
    // Launch 'last' command
    NSArray * last_args = [NSArray arrayWithObjects:@"-c", @"last reboot shutdown", nil];
    NSString * str_logs = [self launchCommand: last_args];
    NSLog(@"str_logs = \n%@", str_logs);
    
    // Get into array
    pattern = @"(reboot|shutdown)";
    
    if ([self regulateString:str_logs :pattern] == nil) return NO;
    NSArray *arrayLog = [self regulateString:str_logs :pattern];
    NSMutableArray *missingLog = [[NSMutableArray alloc] init];

    NSString * checkChar = @"s";
    
    for (i = 0; i < [arrayLog count]; i += 1)
    {
        NSTextCheckingResult * res = [arrayLog objectAtIndex:i];
        int bl = 0;
        
        if (res != nil)
        {
            NSString * word = [str_logs substringWithRange:[res rangeAtIndex:1]];
            NSString * fWord = [word substringWithRange:NSMakeRange(0, 1)];
            
            if (i % 2 == bl)
            {
                if ([fWord isEqualToString:checkChar])
                {
                    [missingLog addObject:[NSNumber numberWithInt:i]];
                    
                    if (bl == 0) bl = 1;
                    else bl = 0;
                    
                    if ([checkChar isEqualToString:@"s"]) checkChar = @"r";
                    else checkChar = @"s";
                }
            }
        }
        
    }
    NSLog(@"missing_log = %@", missingLog);
    
    pattern = @"((S(at|un)|Mon|Wed|(T(ue|hu))|Fri)(\\s)([A-Z]{1}[a-z]{2})(\\s)(\\s|[0-3])([0-9])(\\s)([0-1][\\d]{1}|[2][0-3]{1})(:)([0-5][\\d]))";
    if ([self regulateString:str_logs :pattern] == nil) return NO;
    NSArray *bar = [self regulateString:str_logs :pattern];
    NSMutableArray * tmpArray = [[NSMutableArray alloc] init];
    
    for (i = 0; i < [bar count] - 1; i += 1)
    {
        NSTextCheckingResult * res = [bar objectAtIndex: i];
        
        if (res != nil)
        {
            NSString * value = [str_logs substringWithRange:[res rangeAtIndex:1]];
            
            for (int j = 0; j < missingLog.count; j += 1)
                if (i == [[missingLog objectAtIndex:j] intValue] - 1)
                {
                    [tmpArray addObject: value];
//                    [tmpArray addObject: [tmpArray objectAtIndex:i]];
                }
            
            [tmpArray addObject: value];
            
        }
    }
    NSLog(@"%ld", tmpArray.count);

    NSArray * foo = [tmpArray mutableCopy];
    NSLog(@"foo = %@", foo);
    
    
    long order = 0;
    NSDateFormatter *onlyDate = [[NSDateFormatter alloc] initWithDateFormat:@"%m/%d %H:%M" allowNaturalLanguage:NO];
    
    for (i = 0; i < foo.count - 1; i += 2)
    {
        Log * log;
        NSDate * dateShutdown;
        NSDate * dateReboot;
        NSNumber * numHour;
        NSString * strPeriod;
        NSString * strTimeWaking;
        
        // Create 'Log' Entity
        log = [NSEntityDescription insertNewObjectForEntityForName:@"Log"
                                            inManagedObjectContext:_managedObjectContext];

        // Get 'reboot' time and 'shutdown' time
        if (i == 0)
        {
            dateShutdown = [NSDate date];
            dateReboot = [self regulateDate:[foo objectAtIndex:0]];
            i -= 1;
        }
        else
        {
            dateShutdown = [self regulateDate:[foo objectAtIndex:i]];
            dateReboot = [self regulateDate:[foo objectAtIndex:i + 1]];
        }
        NSLog(@"foo = %@", dateReboot);
        NSLog(@"foo = %@", dateShutdown);
        
        // Calculate interval between reboot and shutdown
        NSTimeInterval tInterval= [dateShutdown timeIntervalSinceDate:dateReboot];
        numHour = [NSNumber numberWithDouble:tInterval / (60 * 60)];
        
        // Get period
        NSString* str_reboot = [onlyDate stringFromDate:dateReboot];
        NSString* str_shutdown = [onlyDate stringFromDate:dateShutdown];
        strPeriod = [NSString stringWithFormat:@"%@ - %@", str_reboot, str_shutdown];

        // Get interval
        if ([numHour doubleValue] / 24 > 1)
        {
            NSNumber* numDay = [NSNumber numberWithDouble:tInterval / (60 * 60 * 24)];
            strTimeWaking = [NSString stringWithFormat:@"%.1f day", [numDay doubleValue]];
        }
        else if ([numHour doubleValue] < 1)
        {
            NSNumber* numMinute = [NSNumber numberWithDouble:tInterval / 60];
            strTimeWaking = [NSString stringWithFormat:@"%d min", [numMinute intValue]];
        }
        else
            strTimeWaking = [NSString stringWithFormat:@"%.1f hour", [numHour doubleValue]];
        
        // Set Log Entity with attributes
        log.order = [NSNumber numberWithLong:order];
        log.sReboot = dateReboot;
        log.sShutDown = dateShutdown;
        log.dTimeWaking = numHour;
        log.sPeriod = strPeriod;
        log.sTimeWaking = strTimeWaking;

        // Commit changes
        if (![_managedObjectContext save:&err])
        {
            NSString *msg = [NSString stringWithFormat:@"error in committing = %@", err];
            [self errMsg:msg];

            return NO;
        }
        
        order += 1;
    }
    
    // Save dataCount
    self.dataCount = (i + 1) / 2;
    [ud setObject:[NSNumber numberWithInt:self.dataCount] forKey:@"DATA_COUNT"];
    NSLog(@"%d", self.dataCount);
    
    
    return YES;
}

// Regulate string and return array
- (NSArray*)regulateString :(NSString*)string :(NSString*)pattern
{
    NSError *err = nil;
    NSRegularExpression *reg =
    [NSRegularExpression regularExpressionWithPattern:pattern
                                              options:0
                                                error:&err];
    
    NSArray *ret = [reg matchesInString:string
                                     options:0
                                       range:NSMakeRange(0, string.length)];

    if (err != nil)
    {
        NSString *msg = [NSString stringWithFormat:@"reg error = %@", err];
        [self errMsg:msg];

        return nil;
    }

    return ret;
}

// Return regulated date
- (NSDate*)regulateDate :(NSString*)strDate
{
    // Get current year
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comps = [calendar components:NSYearCalendarUnit
                                           fromDate:[NSDate date]];
    NSInteger nowYear = comps.year;
    NSLog(@"nowyear : %ld", nowYear);
    
    // Set Format
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"EEE MMM d HH:mm"];
    
    // Set flag
    NSUInteger uintFlag = NSYearCalendarUnit | NSMonthCalendarUnit
    | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit
    | NSSecondCalendarUnit | NSWeekdayCalendarUnit;
    
    NSDate *date = [formatter dateFromString:strDate];
    comps = [calendar components:uintFlag fromDate:date];
    comps.year = nowYear;
    date = [calendar dateFromComponents:comps];
    
    return date;
}

// Arrange list order
- (void)arrangeList
{
    // Set Entity
    NSFetchRequest * request = [[NSFetchRequest alloc] init];
    
    NSEntityDescription * entity = [NSEntityDescription entityForName:@"Log"
                                               inManagedObjectContext:_managedObjectContext];
    [request setEntity:entity];
    
    // Sort in order
    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray * sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];

    [tableView setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

@end
