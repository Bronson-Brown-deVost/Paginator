//
//  ImageProcessor.h
//  QRCode Finder
//
//  Created by Bronson Brown-deVost on 12/5/12.
//  Copyright (c) 2012 Bronson Brown-deVost. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageProcessor : NSObject {
    NSMutableDictionary *calibrationPoints;
    NSLock *lockThread;
    NSMutableArray *dpiValues;
}

- (NSDictionary*) processImageDictionary:(NSDictionary*) imageArray;

@end
