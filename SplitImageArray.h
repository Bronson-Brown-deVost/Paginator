//
//  SplitImageArray.h
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/6/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SplitImageArray : NSObject {
    NSMutableDictionary *imageDict;
}

-(NSDictionary*)imageSplitIntoArray:(NSImage*)imageToSplit;

@end
