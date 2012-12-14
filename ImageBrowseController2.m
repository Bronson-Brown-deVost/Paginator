//
//  ImageBrowseController2.m
//  Browse Images
//
//  Created by Bronson Brown-deVost on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ImageBrowseController2.h"
#import "OpenFileDialog.h"
#import "MyImageObject.h"
#import "Browse_ImagesAppDelegate.h"


/* the controller */
@implementation ImageBrowseController2
@synthesize inputDirectory;
@synthesize outputDirectory;


- (void)awakeFromNib
{
    zoom = 0.99;
    // create two arrays : the first one is our datasource representation,
    // the second one are temporary imported images (for thread safeness) 
    
    mImages2 = [[NSMutableArray alloc] init];
    mImportedImages2 = [[NSMutableArray alloc] init];
    titleIndex = 0;
    
    //allow reordering, animations et set draggind destination delegate
    [mImageBrowser2 setAllowsReordering:YES];
    [mImageBrowser2 setAnimates:YES];
    [mImageBrowser2 setDraggingDestinationDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(exportFiles) name:@"rightProcesslNotification" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addImageButtonClicked:) name:@"loadRightDirectory" object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(resizeBrowser:) name:@"Resize Image Browser" object: nil];
}

- (void)resizeBrowser:(id)sender
{
    // update the zoom value to scale images
    [mImageBrowser2 setZoomValue:zoom];
    // redisplay
    [mImageBrowser2 setNeedsDisplay:YES];
}

/* entry point for reloading image-browser's data and setNeedsDisplay */
- (void)updateDatasource
{
    //-- update our datasource, add recently imported items
    [mImages2 addObjectsFromArray:mImportedImages2];
    
    //-- empty our temporary array
    [mImportedImages2 removeAllObjects];
    
    //-- reload the image browser and set needs display
    [mImageBrowser2 reloadData];
    if (self.inputDirectory == nil) {
        self.inputDirectory = [[[mImages2 objectAtIndex:0] imageUID] stringByDeletingLastPathComponent];
        self.outputDirectory=inputDirectory;
    }

}


#pragma mark -
#pragma mark import images from file system

/* Code that parse a repository and add all items in an independant array,
 When done, call updateDatasource, add these items to our datasource array
 This code is performed in an independant thread.
 */
- (void)addAnImageWithPath:(NSString *)path
{   
    MyImageObject *p;
    p = [[MyImageObject alloc] init];
    
    /* add a path to our temporary array */
    [p setPath:path];
    [p setIndex:[NSString stringWithFormat:@"%d", titleIndex]];
    [mImportedImages2 addObject:p];
    titleIndex++;
}

- (void)addImagesWithPath:(NSString *)path recursive:(BOOL)recursive
{
    NSInteger i, n;
    BOOL dir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
    if (dir)
    {
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        NSArray *extensions = [NSArray arrayWithObjects:@"jpg", @"JPG", @"jpeg", @"JPEG", @"tif", @"TIF", @"tiff", @"TIFF", @"png", @"PNG", @"bmp", @"BMP", nil];
        NSArray *contentFiltered = [content filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", extensions]];
        n = [contentFiltered count];
        
        // parse the directory content
        for (i=0; i<n; i++)
        {
            if (recursive)
                [self addImagesWithPath:[path stringByAppendingPathComponent:[contentFiltered objectAtIndex:i]] recursive:YES];
            else
                [self addAnImageWithPath:[path stringByAppendingPathComponent:[contentFiltered objectAtIndex:i]]];
        }
    }
    else
    {
        [self addAnImageWithPath:path];
    }
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{   
    NSInteger i, n;
    
    @autoreleasepool {
        
        n = [urls count];
        for ( i= 0; i < n; i++)
        {
            NSURL *url = [urls objectAtIndex:i];
            [self addImagesWithPath:[url path] recursive:NO];
        }
        
        /* update the datasource in the main thread */
        [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];
        
    }
}


#pragma mark -
#pragma mark actions

/* "add" button was clicked */
- (IBAction)addImageButtonClicked:(id)sender
{
    mImages2 = [[NSMutableArray alloc] init];
    titleIndex = 0;
    
    OpenFileDialog *openFileDialog;
    openFileDialog = [[OpenFileDialog alloc] init];
    NSArray *urls = [openFileDialog openFiles];
    self.inputDirectory=nil;
    self.outputDirectory=nil;
    
    if (!urls)
    { 
        NSLog(@"No files selected, return..."); 
        return; 
    }
    
    /* launch import in an independent thread */
    [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:urls];
}

/* action called when the zoom slider did change */
- (IBAction)zoomSliderDidChange:(id)sender
{
    zoom = [sender floatValue];
    /* update the zoom value to scale images */
    [mImageBrowser2 setZoomValue:zoom];
    
    /* redisplay */
    [mImageBrowser2 setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark IKImageBrowserDataSource

/* implement image-browser's datasource protocol 
 Our datasource representation is a simple mutable array
 */

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)view
{
    /* item count to display is our datasource item count */
    return [mImages2 count];
}

- (id)imageBrowser:(IKImageBrowserView *)view itemAtIndex:(NSUInteger)index
{
    return [mImages2 objectAtIndex:index];
}


/* implement some optional methods of the image-browser's datasource protocol to be able to remove and reoder items */

/*  remove
 The user wants to delete images, so remove these entries from our datasource.   
 */
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [mImages2 removeObjectsAtIndexes:indexes];
}

// reordering:
// The user wants to reorder images, update our datasource and the browser will reflect our changes
- (BOOL)imageBrowser:(IKImageBrowserView *)view moveItemsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
    NSUInteger index;
    NSMutableArray *temporaryArray;
    
    temporaryArray = [[NSMutableArray alloc] init];
    
    /* first remove items from the datasource and keep them in a temporary array */
    for (index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index])
    {
        if (index < destinationIndex)
            destinationIndex --;
        
        id obj = [mImages2 objectAtIndex:index];
        [temporaryArray addObject:obj];
        [mImages2 removeObjectAtIndex:index];
    }
    
    /* then insert removed items at the good location */
    NSInteger n = [temporaryArray count];
    for (index=0; index < n; index++)
    {
        [mImages2 insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
    }
    
    return YES;
}


#pragma mark -
#pragma mark drag n drop 

/* Drag'n drop support, accept any kind of drop */
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSData *data = nil;
    NSString *errorDescription;
    
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    
    /* look for paths in pasteboard */
    if ([[pasteboard types] containsObject:NSFilenamesPboardType]) 
        data = [pasteboard dataForType:NSFilenamesPboardType];
    
    if (data)
    {
        /* retrieves paths */
        NSArray *filenames = [NSPropertyListSerialization propertyListFromData:data 
                                                              mutabilityOption:kCFPropertyListImmutable 
                                                                        format:nil 
                                                              errorDescription:&errorDescription];
        
        
        /* add paths to our datasource */
        NSInteger i;
        NSInteger n = [filenames count];
        for (i=0; i<n; i++){
            [self addAnImageWithPath:[filenames objectAtIndex:i]];
        }
        
        /* make the image browser reload our datasource */
        [self updateDatasource];
    }
    
    /* we accepted the drag operation */
    return YES;
}

//- (IBAction) exportFiles:(id)sender
- (void) exportFiles
{
    NSMutableDictionary *packagedInfo = [[NSMutableDictionary alloc] init];
    [packagedInfo setObject:mImages2 forKey:@"Image Array"];
    if ([self.outputDirectory length] > 1) {
        [packagedInfo setObject:self.outputDirectory forKey:@"Output Directory"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"receiveRightFileArray" object:self  userInfo: packagedInfo];
}



@end