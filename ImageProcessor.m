//
//  ImageProcessor.m
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/5/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#import "ImageProcessor.h"
#import "CodeLocator.h"

@implementation ImageProcessor

-(id)init
{
    if (self = [super init])
    {
        // Initialization code here
        calibrationPoints = [[NSMutableDictionary alloc] init];
        lockThread = [[NSLock alloc] init];
        dpiValues = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSDictionary*) processImageDictionary:(NSDictionary*) imageDict
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:4];
    NSArray *argArray;
    
    for (id key in imageDict) {
        NSImage *currentImage = [imageDict objectForKey:key];
        switch ([key integerValue]) {
            case 0:
                argArray = [NSArray arrayWithObjects:currentImage, [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:currentImage.size.height], nil];
                [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadArrayInDict:) object:argArray]];
                break;
                
            case 1:
                argArray = [NSArray arrayWithObjects:currentImage, [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:0], nil];
                [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadArrayInDict:) object:argArray]];
                break;
                
            case 2:
                argArray = [NSArray arrayWithObjects:currentImage, [NSNumber numberWithInteger:currentImage.size.width], [NSNumber numberWithInteger:currentImage.size.height], nil];
                [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadArrayInDict:) object:argArray]];
                break;
                
            case 3:
                argArray = [NSArray arrayWithObjects:currentImage, [NSNumber numberWithInteger:currentImage.size.width], [NSNumber numberWithInteger:0], nil];
                [queue addOperation:[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(loadArrayInDict:) object:argArray]];
                break;
                
            default:
                break;
        }
    }
    [queue waitUntilAllOperationsAreFinished];
    
    //Get the averaged DPI and add it to the dictionary
    NSNumber *finalDPI = [NSNumber numberWithFloat:0];
    for (NSNumber *dpi in dpiValues){
        finalDPI = [NSNumber numberWithFloat:[finalDPI floatValue] + [dpi floatValue]];
    }
    finalDPI = [NSNumber numberWithFloat:[finalDPI floatValue]/[dpiValues count]];
    [calibrationPoints setObject:finalDPI forKey:@"DPI"];
    
    //Return results
    return calibrationPoints;
}

//We can multithread the process by processing each slice here
-(void)loadArrayInDict:(NSArray*)argArray
{
    NSArray *results;
    CodeLocator *findCode = [[CodeLocator alloc] init];
    results = [findCode locateCode:[[argArray objectAtIndex:0] CGImageForProposedRect:NULL context:NULL hints:NULL] xOffset:(int)[[argArray objectAtIndex:1] integerValue] yOffset:(int)[[argArray objectAtIndex:2] integerValue]];
    [lockThread lock];
    [calibrationPoints setObject:[results objectAtIndex:1] forKey:[results objectAtIndex:0]];
    [dpiValues addObject:[results objectAtIndex:2]];
    [lockThread unlock];
}

@end
