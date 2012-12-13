//
//  MyImageObject.h
//  Browse Images
//
//  Created by Bronson Brown-deVost on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface MyImageObject : NSObject{
    NSString *_path;
    NSString *_index;
}
- (void)setPath:(NSString *)path;
- (void)setIndex:(NSString *) index;
- (NSString *)imageRepresentationType;
- (NSString *) imageTitle;
- (id)imageRepresentation;
- (NSString *)imageUID;
@end
