//
//  ImageBrowserController.m
//  Browse Images
//
//  Created by Bronson Brown-deVost on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "ImageBrowserController.h"
#import "OpenFileDialog.h"
#import "MyImageObject.h"
#import "ImageFileProcessor.h"
#import <Quartz/Quartz.h>

/* the controller */
@implementation ImageBrowserController
@synthesize inputDirectory;
@synthesize outputDirectory;
@synthesize dpiTextField;
@synthesize processingLabel;
@synthesize outputTypePopup;
@synthesize progressIndicator;
@synthesize progressSpinner;

# pragma mark - Initial Setup
- (void)awakeFromNib
{
    titleIndex = 0;
    zoom = 0.99;
    // create two arrays : the first one is our datasource representation,
    // the second one are temporary imported images (for thread safeness) 
    
    mImages = [[NSMutableArray alloc] init];
    mImportedImages = [[NSMutableArray alloc] init];
    
    //allow reordering, animations et set draggind destination delegate
    [mImageBrowser setAllowsReordering:YES];
    [mImageBrowser setAnimates:YES];
    [mImageBrowser setDraggingDestinationDelegate:self];
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setMinValue:0.0];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setDisplayedWhenStopped:NO];
    [progressIndicator setHidden:YES];
    [progressSpinner setStyle:1];
    [progressSpinner setDisplayedWhenStopped:false];
    [progressSpinner setUsesThreadedAnimation:YES];
    [processingLabel setHidden:YES];
    
    [outputTypePopup removeAllItems];
    [outputTypePopup addItemWithTitle:@"Full Color"];
    [outputTypePopup addItemWithTitle:@"Gray Scale"];
    [outputTypePopup addItemWithTitle:@"Black and White"];
    
    [outputTypePopup selectItemAtIndex:0];
    
    [dpiTextField setStringValue:@"300"];
    
    //Listen for the array of image files for the Right side.
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receiveRightFiles:) name:@"receiveRightFileArray" object: nil];
}

- (void)windowDidResize:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Resize Image Browser" object: nil];
    // update the zoom value to scale images
    [mImageBrowser setZoomValue:zoom];
    // redisplay 
    [mImageBrowser setNeedsDisplay:YES];
}

# pragma mark - Image Browser Setup
/* entry point for reloading image-browser's data and setNeedsDisplay */
- (void)updateDatasource
{
    //-- update our datasource, add recently imported items
    [mImages addObjectsFromArray:mImportedImages];
    
    //-- empty our temporary array
    [mImportedImages removeAllObjects];
    
    //-- reload the image browser and set needs display
    [mImageBrowser reloadData];
    if (self.inputDirectory == nil) {
        self.inputDirectory = [[[mImages objectAtIndex:0] imageUID] stringByDeletingLastPathComponent];
        self.outputDirectory=[inputDirectory stringByDeletingLastPathComponent];
    }
}

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
    [mImportedImages addObject:p];
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

/* "add" button was clicked */
- (IBAction)addImageButtonClicked:(id)sender
{
    mImages = [[NSMutableArray alloc] init];
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
    [self checkIfLoadRightPages];
}

-(void)checkIfLoadRightPages
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];
    [alert setMessageText:@"Do you want to load right pages from another directory?"];
    [alert setAlertStyle:NSWarningAlertStyle];
    //Wait a bit for the right page query dialof to display nicely
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(rightAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

//Check if user wants to load right hand pages from a different directory
- (void)rightAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"loadRightDirectory" object: nil];
    }
}

/* action called when the zoom slider did change */
- (IBAction)zoomSliderDidChange:(id)sender
{
    zoom = [sender floatValue];
    /* update the zoom value to scale images */
    [mImageBrowser setZoomValue:zoom];
    
    /* redisplay */
    [mImageBrowser setNeedsDisplay:YES];
}

/* implement image-browser's datasource protocol 
 Our datasource representation is a simple mutable array
 */

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)view
{
    /* item count to display is our datasource item count */
    return [mImages count];
}

- (id)imageBrowser:(IKImageBrowserView *)view itemAtIndex:(NSUInteger)index
{
    return [mImages objectAtIndex:index];
}

/*  remove
 The user wants to delete images, so remove these entries from our datasource.   
 */
- (void)imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
    [mImages removeObjectsAtIndexes:indexes];
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
        
        id obj = [mImages objectAtIndex:index];
        [temporaryArray addObject:obj];
        [mImages removeObjectAtIndex:index];
    }
    
    /* then insert removed items at the good location */
    NSInteger n = [temporaryArray count];
    for (index=0; index < n; index++)
    {
        [mImages insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
    }

    
    return YES;
}

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

# pragma mark - Image Processing Control
- (IBAction) startProcessingFiles:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"YES"];
    [alert addButtonWithTitle:@"NO"];
    [alert setMessageText:@"Do you want to select different output directory?"];
    [alert setInformativeText:[NSString stringWithFormat:@"The current output directory is: %@", outputDirectory]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(directoryAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

//Check if user wants to set a different output directory
- (void)directoryAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
        NSOpenPanel *getOutputDirectory = [NSOpenPanel openPanel];
        [getOutputDirectory setCanChooseFiles:NO];
        [getOutputDirectory setCanChooseDirectories:YES];
        [getOutputDirectory setCanCreateDirectories:YES];
        [getOutputDirectory setResolvesAliases:NO];
        [getOutputDirectory setAllowsMultipleSelection:NO];
        [getOutputDirectory runModal];
        
        //Get source folder name
        NSURL* source = [[getOutputDirectory URLs] objectAtIndex: 0];
        self.outputDirectory = [source path];
        [self processFiles];
    } else [self processFiles];
}

- (void) processFiles
{
    if ([progressIndicator isHidden]) {
        //If we set the DPI here it can't be changed in the middle of a processing job.
        dpi = (int)[dpiTextField integerValue];
        
        [progressSpinner startAnimation:self];
        [progressIndicator setHidden:NO];
        [processingLabel setHidden:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"rightProcesslNotification" object: nil];
    }
    
}

//This receives a callback from ImageBrowser2 and gets the file list from it.  It then starts processing the files.
-(void) receiveRightFiles:(NSNotification*)notification
{
    int pageInterval;
    NSDictionary *dict = [notification userInfo];
    mImages2 = [dict objectForKey:@"Image Array"];
    [progressIndicator setMaxValue:[mImages count] + [mImages2 count]];
    [progressIndicator startAnimation:self];
    [progressIndicator setDoubleValue:(double)0];
    [progressIndicator display];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:2];
    
    //Check whether left, right, both, or no sets of pages exist and run accordingly.
    
    if (self.outputDirectory == nil) {
        self.outputDirectory = [dict objectForKey:@"Output Directory"];
    }
    
    if (outputDirectory != nil) {
        if ([mImages count] == 0 || [mImages2 count] == 0) {
            pageInterval = 1;
        } else pageInterval = 2;
        
        if (![mImages count] == 0) {
            NSArray *argArray = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:pageInterval], [outputTypePopup titleOfSelectedItem], [NSNumber numberWithBool:YES], nil];
            [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(prepareFilesForProcessing:) object:argArray]];
        }
        if (![mImages2 count] == 0) {
            NSArray *argArray = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:pageInterval], [outputTypePopup titleOfSelectedItem], [NSNumber numberWithBool:NO], nil];
            [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(prepareFilesForProcessing:) object:argArray]];
        }
    }
}

-(void)prepareFilesForProcessing:(NSArray*)receivedArgs
{
    int pageInterval = [[receivedArgs objectAtIndex:0] intValue];
    NSString *colorOption = [receivedArgs objectAtIndex:1];
    BOOL isLeftPage = [[receivedArgs objectAtIndex:2] boolValue];
    int index;
    NSArray *filesToProcess;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:2];
    
    //Check for left or right page and setup accordingly
    if (isLeftPage) {
        index = 0;
        filesToProcess = mImages;
    }
    if (!isLeftPage) {
        index = 1;
        filesToProcess = mImages2;
    }
    
    for (MyImageObject *selectedImage in filesToProcess){
        NSArray *argArray = [NSArray arrayWithObjects:selectedImage, [NSNumber numberWithInt:index], colorOption, nil];
        [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(processImage:) object:argArray]];
        index += pageInterval;
    }
}

-(void)processImage:(NSArray*) argArray
{
    //Timer function
    NSDate *start = [NSDate date];
    //Timer function
    
    MyImageObject *selectedImage = [argArray objectAtIndex:0];
    NSImage *currentImage = [[NSImage alloc] initWithContentsOfFile:[selectedImage imageUID]];
    int index = (int)[[argArray objectAtIndex:1] integerValue];
    NSString *colorOption = [argArray objectAtIndex:2];
    ImageFileProcessor *fileProcessor = [[ImageFileProcessor alloc] init];
    
    //I am currently hardcoding the reduction factor (ZXing won't detect the QR Code if the image is too big.
    //Perhaps we can make this more intelligent later.
    currentImage = [fileProcessor process:currentImage atDPI:dpi withColorOption:colorOption reducedBy:3];
    [self writeFileFromImage:currentImage atIndex:index];
    [progressIndicator incrementBy:1];
    
    //Shut down progress indication when finished.
    if ([progressIndicator maxValue] == [progressIndicator doubleValue]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Your images have been processed."];
            [alert setInformativeText:[NSString stringWithFormat:@"They have been saved in the folder: %@.", outputDirectory]];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
        });
        [processingLabel setHidden:YES];
        [progressSpinner stopAnimation:self];
        [progressIndicator stopAnimation:self];
        [progressIndicator setHidden:YES];
    }
    
    //Timer function
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    NSLog(@"Time to fully process and write 1 image: %f", executionTime);
    //Timer function
}

-(void)writeFileFromImage:(NSImage*)processedImage atIndex:(int)index
{
    //Timer function
    NSDate *start = [NSDate date];
    //Timer function
    NSString *writeFileName = [self.outputDirectory stringByAppendingString:[NSString stringWithFormat:@"/%05d.tiff", index]];
    [processedImage saveAsImageType:NSTIFFCompressionLZW withDPI:dpi atPath:writeFileName];
    //Timer function
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    NSLog(@"Time to write file to disk: %f", executionTime);
    //Timer function
}

- (IBAction)printQRCodes:(id)sender
{
    // Create the print settings.
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin:0.0];
    [printInfo setBottomMargin:0.0];
    [printInfo setLeftMargin:0.0];
    [printInfo setRightMargin:0.0];
    [printInfo setHorizontalPagination:NSFitPagination];
    [printInfo setVerticalPagination:NSFitPagination];
    
    NSBundle* myBundle = [NSBundle mainBundle];
    NSString* pdfToPrint = [myBundle pathForResource:@"QR Calibration Codes" ofType:@"png"];
    NSImage *nsImage = [[NSImage alloc] initWithContentsOfFile:pdfToPrint];
    
    NSImageView *nsImageView = [[NSImageView alloc] init];
    NSSize imageSize = [nsImage size];
    [nsImageView setImage: (NSImage *)nsImage];
    [nsImageView setFrame:NSMakeRect(0, 0, imageSize.width, imageSize.height)];
    
    NSPrintOperation *nsPO = [NSPrintOperation printOperationWithView: (NSView *)nsImageView];
    
    [nsPO setPrintInfo:printInfo];
    [nsPO setShowsPrintPanel:YES];
    [nsPO setShowsProgressPanel:YES];
    
    [nsPO runOperation];
}
@end

# pragma mark - NSImage Interface
//This is a handy way to save NSImages to disk with the right DPI
@implementation NSImage (DPIHelper)

- (void) saveAsImageType: (NSBitmapImageFileType) imageType withDPI: (CGFloat) dpiValue atPath: (NSString *) filePath
{
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
    
    NSSize pointsSize = rep.size;
    NSSize pixelSize = NSMakeSize(rep.pixelsWide, rep.pixelsHigh);
    
    NSSize updatedPointsSize = pointsSize;
    
    updatedPointsSize.width = ceilf((72.0f * pixelSize.width)/dpiValue);
    updatedPointsSize.height = ceilf((72.0f * pixelSize.height)/dpiValue);
    
    [rep setSize:updatedPointsSize];
    
    NSData *data = [rep representationUsingType: imageType properties: nil];
    [data writeToFile: filePath atomically: NO];
}

@end

