//
//  ImageBrowseController2.h
//  Browse Images
//
//  Created by Bronson Brown-deVost on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface ImageBrowseController2 : NSWindowController{
    
    IBOutlet id mImageBrowser2;
    NSMutableArray * mImages2;
    NSMutableArray * mImportedImages2;
    float zoom;
    int titleIndex;
}

@property (nonatomic, strong) NSString* inputDirectory;
@property (nonatomic, strong) NSString* outputDirectory;

- (IBAction) addImageButtonClicked:(id) sender;
- (IBAction) zoomSliderDidChange:(id)sender;
- (void) exportFiles;

@end