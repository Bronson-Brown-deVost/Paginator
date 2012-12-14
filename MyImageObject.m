//
//  MyImageObject.m
//  Browse Images
//
//  Created by Bronson Brown-deVost on 10/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyImageObject.h"

@implementation MyImageObject

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


/* our datasource object is just a filepath representation */
- (void)setPath:(NSString *)path
{
    if(_path != path)
    {
        _path = path;
    }
}

- (void)setIndex:(NSString *) index
{
    if(_index != index)
    {
        _index = index;
    }
}

/* required methods of the IKImageBrowserItem protocol */
#pragma mark -
#pragma mark item data source protocol

/* let the image browser knows we use a path representation */
- (NSString *)imageRepresentationType
{
    return IKImageBrowserPathRepresentationType; 
}

- (NSString *) imageTitle
{
    //IKImageBrowserCell *cell = [IKImageBrowserCell this];
    return _index;
}



/* give our representation to the image browser */
- (id)imageRepresentation
{
    return _path;
}

/* use the absolute filepath as identifier */
- (NSString *)imageUID
{
    return _path;
}

@end
