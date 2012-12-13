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

- (NSImage*)process:(NSImage*)initialImage atDPI:(int)targetDPI withColorOption:(NSString*)colorOption
{
    SplitImageArray *imageSplitter = [[SplitImageArray alloc] init];
    NSDictionary *splitImageDict = [imageSplitter imageSplitIntoArray:initialImage];
    
    ImageProcessor *processImage = [[ImageProcessor alloc] init];
    NSDictionary *dictData = [processImage processImageDictionary:splitImageDict];
    
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
    
    float dpi = [[dictData objectForKey:@"DPI"] floatValue];
    
    cv::Mat original = [self cvMatFromNSImage:initialImage];
    //Calculate proper width and height
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

@end
