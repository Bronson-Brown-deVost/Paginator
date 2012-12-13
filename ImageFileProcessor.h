//
//  ImageFileProcessor.h
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/7/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageFileProcessor : NSObject

- (NSImage*)process:(NSImage*)initialImage atDPI:(int)targetDPI withColorOption:(NSString*)colorOption;

@end
