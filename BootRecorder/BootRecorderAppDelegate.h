//
//  BootRecorderAppDelegate.h
//  BootRecorder
//
//  Created by JO Hiroshi on 4/28/13.
//  Copyright (c) 2013 joh. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BootRecorderAppDelegate : NSObject <NSApplicationDelegate>
{
    IBOutlet NSArrayController *arrayController;
    IBOutlet NSManagedObjectContext* managedObjectContext;

    IBOutlet NSTableView* tableView;
    IBOutlet NSButton* button;
}

@property (assign) IBOutlet NSWindow *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property BOOL isDataRead;
@property int dataCount;

- (IBAction)saveAction:(id)sender;
- (IBAction)initFrame:(id)sender;

@end
