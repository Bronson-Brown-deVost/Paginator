//
//  CodeLocator.m
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/5/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#import "CodeLocator.h"
#import <ZXingObjC/ZXingObjC.h>


@implementation CodeLocator

-(id)init
{
    if (self = [super init])
    {
        NSArray *keys = [NSArray arrayWithObjects:@"top left", @"top right", @"bottom right", @"bottom left", nil];
        NSArray *objects = [NSArray arrayWithObjects: [NSNumber numberWithInteger:0], [NSNumber numberWithInteger:1], [NSNumber numberWithInteger:2], [NSNumber numberWithInteger:3], nil];
        codeTables = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    }
    return self;
}

-(NSArray*) locateCode:(CGImageRef)imageForProcessing xOffset:(int)x yOffset:(int)y
{
    ZXLuminanceSource* source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:imageForProcessing];
    ZXBinaryBitmap* bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
    
    NSError* error = nil;
    
    // There are a number of hints we can give to the reader, including
    // possible formats, allowed lengths, and the string encoding.
    ZXDecodeHints* hints = [ZXDecodeHints hints];
    [hints addPossibleFormat:kBarcodeFormatQRCode];
    
    
    ZXMultiFormatReader* reader = [ZXMultiFormatReader reader];
    ZXResult* result = [reader decode:bitmap hints:hints error:&error];
    if (!result) {
        //If we don't find a QR Code we try really hard to find one.
            NSLog(@"We have had to try harder to find the QR Code.");
            [hints setTryHarder:YES];
            result = [reader decode:bitmap hints:hints error:&error];
        if (!result) {
            //Let's throw a popup up here and perhaps process the page using the last known parameters
            NSLog(@"Failed to find code.");
            NSLog(@"%@", [error localizedDescription]);
        }
    }
    return [self calculateResult:result xOffset:x yOffset:y leftPage:[self isLeftPage:result.text]];
}

-(NSArray*) calculateResult:(ZXResult*)result xOffset:(int)x yOffset:(int)y leftPage:(BOOL)leftPage
{
    NSArray *codeData;
    NSNumber *switchSelection;
    NSPoint offset;
    offset = [self setDPIGetOffset:[[[result resultPoints] objectAtIndex:0] y] and:[[[result resultPoints] objectAtIndex:1] y] and:[[[result resultPoints] objectAtIndex:1] x] and:[[[result resultPoints] objectAtIndex:2] x]];
    
    NSArray *segmentedString=[result.text componentsSeparatedByString:@" "];
    NSString *pagePosition = [[segmentedString objectAtIndex:2] stringByAppendingString:[NSString stringWithFormat:@" %@",[segmentedString objectAtIndex:3]]];
    switchSelection = [codeTables objectForKey:pagePosition];
    
    NSPoint calibrationPoint;
    if (leftPage) {
        switch ([switchSelection intValue]) {
            case 0:
                //NSLog(@"Found %@ corner for case 0", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:1] x] + offset.x, [[[result resultPoints] objectAtIndex:1] y] + offset.y);
                break;
                
            case 1:
                //NSLog(@"Found %@ corner for case 1", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:1] x] + offset.x, [[[result resultPoints] objectAtIndex:1] y] + offset.y);
                break;
                
            case 2:
                //NSLog(@"Found %@ corner for case 2", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:2] x] + offset.x, [[[result resultPoints] objectAtIndex:2] y] - offset.y);
                break;
                
            case 3:
                //NSLog(@"Found %@ corner for case 3", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:2] x] + offset.x, [[[result resultPoints] objectAtIndex:2] y] - offset.y);
                break;
                
            default:
                break;
        }
    }
    
    if (!leftPage) {
        switch ([switchSelection intValue]) {
            case 0:
                //NSLog(@"Found %@ corner for case 0", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:2] x] - offset.x, [[[result resultPoints] objectAtIndex:2] y] + offset.y);
                break;
                
            case 1:
                //NSLog(@"Found %@ corner for case 1", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:2] x] - offset.x, [[[result resultPoints] objectAtIndex:2] y] + offset.y);
                break;
                
            case 2:
                //NSLog(@"Found %@ corner for case 2", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:1] x] - offset.x, [[[result resultPoints] objectAtIndex:1] y] - offset.y);
                break;
                
            case 3:
                //NSLog(@"Found %@ corner for case 3", result.text);
                calibrationPoint = NSMakePoint([[[result resultPoints] objectAtIndex:1] x] - offset.x, [[[result resultPoints] objectAtIndex:1] y] - offset.y);
                break;
                
            default:
                break;
        }
    }
    
    calibrationPoint.x += x;
    calibrationPoint.y += y;
    codeData = [NSArray arrayWithObjects:result.text, [NSValue valueWithPoint:calibrationPoint], [NSNumber numberWithFloat:dpi], nil];
    return codeData;
}

-(BOOL) isLeftPage:(NSString*)identification
{
    BOOL isLeftPage;
    
    NSString *searchForMe = @"left page";
    NSRange range = [identification rangeOfString : searchForMe];
    if (range.location != NSNotFound) {
        isLeftPage = YES;
    }
    
    searchForMe = @"right page";
    range = [identification rangeOfString : searchForMe];
    if (range.location != NSNotFound) {
        isLeftPage = NO;
    }
    
    return isLeftPage;
}

-(NSPoint)setDPIGetOffset:(float)first and:(float)second and:(float)third and:(float)fourth
{
    float horizDPI = fabsf(third-fourth);
    float vertDPI = fabsf(first-second);
    //We need to check whether the divisor here works for all sizes of documents!!!
    NSPoint xyDPI = {horizDPI*0.45, vertDPI*0.45};
    dpi = (horizDPI + vertDPI)/2;
    return (xyDPI);
}

@end
