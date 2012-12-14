//
//  ImageFileProcessor.m
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/7/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#include <opencv2/opencv.hpp>
#import "ImageFileProcessor.h"
#import <QuartzCore/QuartzCore.h>
#import "ImageProcessor.h"
#import "SplitImageArray.h"

@implementation ImageFileProcessor

- (NSImage*)process:(NSImage*)initialImage atDPI:(int)targetDPI withColorOption:(NSString*)colorOption reducedBy:(float)reductionFactor
{
    //Timer function
    NSDate *start = [NSDate date];
    //Timer function
    
    NSImage* reducedImageForQRCode = [self resizeImage:initialImage reduceBy:reductionFactor];
    
    //Timer function
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];
    NSLog(@"Time to run image resizing: %f", executionTime);
    //Timer function
    
    /*
    //Write file for diagnostic purposes
    [reducedImageForQRCode saveAsImageType:NSTIFFFileType atPath:@"/Volumes/Leopard/Users/bronson/Desktop/test.tif"];
     */
    
    //Timer function
    start = [NSDate date];
    //Timer function
    
    SplitImageArray *imageSplitter = [[SplitImageArray alloc] init];
    NSDictionary *splitImageDict = [imageSplitter imageSplitIntoArray:reducedImageForQRCode];
    
    //Timer function
    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:start];
    NSLog(@"Time to run split image: %f", executionTime);
    //Timer function
    
    //Timer function
    start = [NSDate date];
    //Timer function
    
    ImageProcessor *processImage = [[ImageProcessor alloc] init];
    NSDictionary *dictData = [processImage processImageDictionary:splitImageDict];
    
    //Timer function
    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:start];
    NSLog(@"Time to run process image: %f", executionTime);
    //Timer function
    
    //Timer function
    start = [NSDate date];
    //Timer function
    
    NSString *page;
    for (NSString *key in dictData) {
        page = key;
    }
    NSRange wordRange = NSMakeRange(0,2);
    NSArray *pageType = [[page componentsSeparatedByString:@" "] subarrayWithRange:wordRange];
    NSString *pagePosition = [pageType componentsJoinedByString:@" "];
    
    NSPoint bottomLeft;
    NSPoint bottomRight;
    NSPoint topLeft;
    NSPoint topRight;
                       
    if ([pagePosition isEqualToString:@"left page"]) {
        bottomLeft = [[dictData objectForKey:@"left page bottom left"] pointValue];
        bottomRight = [[dictData objectForKey:@"left page bottom right"] pointValue];
        topLeft = [[dictData objectForKey:@"left page top left"] pointValue];
        topRight = [[dictData objectForKey:@"left page top right"] pointValue];
    }
    
    if ([pagePosition isEqualToString:@"right page"]) {
        bottomLeft = [[dictData objectForKey:@"right page bottom left"] pointValue];
        bottomRight = [[dictData objectForKey:@"right page bottom right"] pointValue];
        topLeft = [[dictData objectForKey:@"right page top left"] pointValue];
        topRight = [[dictData objectForKey:@"right page top right"] pointValue];
    }
    
    //Now we must scale the points up for the full size image.
    //Perhaps we can find a more elegant way of doing this later.
    topLeft.x *= reductionFactor;
    topLeft.y *= reductionFactor;
    topRight.x *= reductionFactor;
    topRight.y *= reductionFactor;
    bottomRight.x *= reductionFactor;
    bottomRight.y *= reductionFactor;
    bottomLeft.x *= reductionFactor;
    bottomLeft.y *= reductionFactor;
    
    //Collect the DPI data
    float dpi = [[dictData objectForKey:@"DPI"] floatValue];
    
    /* We could try processing the image with Core Image
    NSData  * tiffData = [initialImage TIFFRepresentation];
    CIImage *backgroundCIImage = [[CIImage alloc] initWithData:tiffData];
    CGRect cgRect = [backgroundCIImage extent];
    NSRect nsRect = NSMakeRect(cgRect.origin.x,\
                               cgRect.origin.y, cgRect.size.width, cgRect.size.height);
    
    if ([initialImage isFlipped]) {
        CGAffineTransform transform;
        transform = CGAffineTransformMakeTranslation(0.0,cgRect.size.height);
        transform = CGAffineTransformScale(transform, 1.0, -1.0);
        backgroundCIImage = [backgroundCIImage imageByApplyingTransform:transform];
    }
    
    [backgroundCIImage drawAtPoint:NSZeroPoint fromRect:nsRect
               operation:NSCompositeSourceOver fraction:1.0];
    CIFilter* filter = [CIFilter filterWithName: @"CIPerspectiveTransform"];
    [filter setDefaults];
    [filter setValue: backgroundCIImage forKey: @"inputImage"];
    
    CIVector* tRight = [CIVector vectorWithX: topRight.x Y: topLeft.x];
    CIVector* tLeft = [CIVector vectorWithX: topLeft.x Y: topLeft.y];
    CIVector* bRight = [CIVector vectorWithX: bottomRight.x Y: bottomRight.y];
    CIVector* bLeft = [CIVector vectorWithX: bottomLeft.x Y: bottomLeft.y];
    
    [filter setValue: tLeft forKey: @"inputTopLeft"];
    [filter setValue: tRight forKey: @"inputTopRight"];
    [filter setValue: bRight forKey: @"inputBottomRight"];
    [filter setValue: bLeft forKey: @"inputBottomLeft"];
    
    CIImage* deskewedImage = [filter valueForKey: @"outputImage"];
    NSImage *newImage = [self imageWithCIImage:deskewedImage fromRect:[deskewedImage extent]];*/
                       
                       
    
    cv::Mat original = [self cvMatFromNSImage:initialImage];
    
    
    //Calculate proper width and height
    //Not sure why this doesn't work for landscape images
    CGFloat w1 = sqrt( pow(bottomRight.x - bottomLeft.x , 2) + pow(bottomRight.x - bottomLeft.x, 2));
    CGFloat w2 = sqrt( pow(topRight.x - topLeft.x , 2) + pow(topRight.x - topLeft.x, 2));
     
    CGFloat h1 = sqrt( pow(topRight.y - bottomRight.y , 2) + pow(topRight.y - bottomRight.y, 2));
    CGFloat h2 = sqrt( pow(topLeft.y - bottomLeft.y , 2) + pow(topLeft.y - bottomLeft.y, 2));
     
    CGFloat maxWidth = (w1 < w2) ? w1 : w2;
    CGFloat maxHeight = (h1 < h2) ? h1 : h2;
    
    //Adjust width and height for DPI
    maxWidth = (maxWidth/dpi)*targetDPI;
    maxHeight = (maxHeight/dpi)*targetDPI;
    
    //Setup matrix
    cv::Point2f src[4], dst[4];
    src[0].x = topLeft.x;
    src[0].y = topLeft.y;
    src[1].x = topRight.x;
    src[1].y = topRight.y;
    src[2].x = bottomRight.x;
    src[2].y = bottomRight.y;
    src[3].x = bottomLeft.x;
    src[3].y = bottomLeft.y;
    
    dst[0].x = 0;
    dst[0].y = 0;
    dst[1].x = maxWidth;
    dst[1].y = 0;
    dst[2].x = maxWidth;
    dst[2].y = maxHeight;
    dst[3].x = 0;
    dst[3].y = maxHeight;
    
    //Perform undistortion
    cv::Mat undistorted = cv::Mat( cvSize(maxWidth,maxHeight), CV_8UC1);
    cv::warpPerspective(original, undistorted, cv::getPerspectiveTransform(src, dst), cvSize(maxWidth, maxHeight));
    
    
    if ([colorOption isEqualToString:@"Gray Scale"]) {
        cv::cvtColor(undistorted, undistorted, CV_BGR2GRAY );
    }
    
    if ([colorOption isEqualToString:@"Black and White"]) {
        cv::cvtColor(undistorted, undistorted, CV_BGR2GRAY );
        cv::threshold(undistorted, undistorted, 100, 255, CV_THRESH_OTSU);
    }
    //cv::norm(undistorted, undistorted);
    
    //Write and return NSImage
    NSImage *newImage = [self NSImageFromCVMat:undistorted];
    
    //Timer function
    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:start];
    NSLog(@"Time to run image transform: %f", executionTime);
    //Timer function
    
    return newImage;
}

//Convert cvMat to NSImage
- (NSImage *)NSImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

//Convert NSImage to cvMat
- (cv::Mat)cvMatFromNSImage:(NSImage *)image
{
    //The following command doesn't work with monochrome images, let's find a way to fix that!!!
    CGColorSpaceRef colorSpace = CGImageGetColorSpace([image CGImageForProposedRect:NULL context:NULL hints:NULL]);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), [image CGImageForProposedRect:NULL context:NULL hints:NULL]);
    CGContextRelease(contextRef);
    
    return cvMat;
}

-(NSImage*)resizeImage:(NSImage*)initialImage reduceBy:(float)reductionFactor
{
    NSImage *sourceImage = [initialImage copy];
    float width = [sourceImage size].width/reductionFactor;
    float height = [sourceImage size].height/reductionFactor;
    // Report an error if the source isn't a valid image
    if (![sourceImage isValid])
    {
        NSLog(@"Invalid Image");
    } else {
        NSImage *smallImage = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
        [smallImage lockFocus];
        [sourceImage setSize:NSMakeSize(width, height)];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        //[sourceImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
        [sourceImage drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0,0, [smallImage size].width, [smallImage size].height) operation:NSCompositeCopy fraction:1.0];
        [smallImage unlockFocus];
        return smallImage;
    }
    return nil;
}

/* This would be useful fore Core Image processing
- (NSImage *)imageWithCIImage:(CIImage *)i fromRect:(CGRect)r
    {
        NSImage *image;
        NSCIImageRep *ir;
        
        ir = [NSCIImageRep imageRepWithCIImage:i];
        image = [[NSImage alloc] initWithSize:
                  NSMakeSize(r.size.width, r.size.height)];
        [image addRepresentation:ir];
        return image;
    }
 
 - (CIImage *)newCIImage
 {
 return [[CIImage alloc] initWithBitmapImageRep:[NSBitmapImageRep imageRepWithData:[self TIFFRepresentation]]];
 }*/

@end

/*
//This is for Diagnostic use only!!!
# pragma mark - NSImage Interface
//This is a handy way to save NSImages to disk.
@implementation NSImage (FileWriter)

- (void) saveAsImageType: (NSBitmapImageFileType)imageType atPath:(NSString *)filePath
{
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
    
    NSData *data = [rep representationUsingType: imageType properties: nil];
    [data writeToFile: filePath atomically: NO];
}
@end
 */
