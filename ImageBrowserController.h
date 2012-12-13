//
//  ImageBrowserController.h
//  Browse Images
//
//  Created by Bronson Brown-deVost on 9/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ImageBrowserController : NSWindowController{
    
    IBOutlet id mImageBrowser;
    NSMutableArray * mImages;
    NSMutableArray * mImportedImages;
    NSMutableArray * mImages2;
    float zoom;
    int titleIndex;
    int dpi;
}

@property (nonatomic, strong) NSString* inputDirectory;
@property (nonatomic, strong) NSString* outputDirectory;
@property (unsafe_unretained) IBOutlet NSTextField *dpiTextField;
@property (unsafe_unretained) IBOutlet NSTextField *processingLabel;
@property (unsafe_unretained) IBOutlet NSPopUpButton *outputTypePopup;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progressIndicator;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progressSpinner;

- (IBAction) addImageButtonClicked:(id) sender;
- (IBAction) zoomSliderDidChange:(id)sender;
- (IBAction) startProcessingFiles:(id)sender;
- (IBAction)printQRCodes:(id)sender;

-(void) receiveRightFiles:(NSArray*)receivedArray;
@end

@interface NSImage (DPIHelper)
- (void) saveAsImageType: (NSBitmapImageFileType) imageType withDPI: (CGFloat) dpiValue atPath: (NSString *) filePath;
@end
