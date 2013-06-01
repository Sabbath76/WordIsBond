//
//  CRSSItem.h
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRSSItem : NSObject

//This method kicks off a parse of a URL at a specified string
- (void)setup;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *imageURLString;
@property (nonatomic, retain) NSString *mediaURLString;
@property (nonatomic, retain) UIImage *appIcon;

@end
