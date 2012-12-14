//
//  OpenFileDialog.m
//  Browse Images
//
//  Created by Bronson Brown-deVost on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenFileDialog.h"

@implementation OpenFileDialog

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (NSArray *) openFiles
{ 
    NSOpenPanel *panel;
    
    panel = [NSOpenPanel openPanel];        
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    NSInteger i = [panel runModal];
    if (i == NSOKButton)
    {
        return [panel URLs];
    }
    
    return nil;
}

@end
