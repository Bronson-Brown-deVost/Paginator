//
//  Browse_ImagesAppDelegate.h
//  Browse Images
//
//  Created by Bronson Brown-deVost on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Browse_ImagesAppDelegate : NSObject <NSApplicationDelegate> {
    NSPersistentStoreCoordinator *__persistentStoreCoordinator;
    NSManagedObjectModel *__managedObjectModel;
    NSManagedObjectContext *__managedObjectContext;
    
}

@property (nonatomic, strong) IBOutlet NSWindow *window;

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
- (IBAction)saveAction:(id)sender;

@end
