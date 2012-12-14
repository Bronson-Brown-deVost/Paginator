//
//  SplitImageArray.m
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/6/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#import "SplitImageArray.h"

@implementation SplitImageArray

-(id)init
{
    if (self = [super init])
    {
        // Initialization code here
        imageDict = [[NSMutableDictionary alloc]  init];
    }
    return self;
}

-(NSDictionary*)imageSplitIntoArray:(NSImage*)imageToSplit
{
    NSArray *argArray;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:4];
    int kXSlices = 2;
    int kYSlices = 2;
    int index = 0;
    
    for(int x = 0;x < kXSlices;x++) {
        for(int y = 0;y < kYSlices;y++) {
            CGRect frame = CGRectMake((imageToSplit.size.width / kXSlices) * x,
                                      (imageToSplit.size.height / kYSlices) * y,
                                      (imageToSplit.size.width / kXSlices),
                                      (imageToSplit.size.height / kYSlices));
            argArray = [NSArray arrayWithObjects:[NSValue valueWithRect:frame], imageToSplit, [NSNumber numberWithInt:index], nil];
            [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(imageWithRect:) object:argArray]];
            index++;
        }
    }
    [queue waitUntilAllOperationsAreFinished];
    return imageDict;
}

//We can multithread the process by creating each slice here
- (void)imageWithRect:(NSArray*) argArray;
{
    CGRect frame = [[argArray objectAtIndex:0] rectValue];
    NSPoint zero = { 0.0, 0.0 };
    NSImage *result = [[NSImage alloc] initWithSize:frame.size];
    
    [result lockFocus];
    [[argArray objectAtIndex:1] drawAtPoint:zero fromRect:frame operation:NSCompositeCopy fraction:1];
    [result unlockFocus];
    
    [imageDict setObject:result forKey:[NSString stringWithFormat:@"%li", [[argArray objectAtIndex:2] integerValue]]];
}

@end
