//
//  CodeLocator.h
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/5/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CodeLocator : NSObject {
    NSDictionary *leftCodeTables;
    NSDictionary *rightCodeTables;
    NSDictionary *codeTables;
    float dpi;
}

-(NSArray*) locateCode:(CGImageRef)imageForProcessing xOffset:(int)x yOffset:(int)y;

@end
