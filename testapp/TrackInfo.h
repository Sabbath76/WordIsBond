//
//  TrackInfo.h
//  WordIsBond
//
//  Created by Jose Lopes on 09/11/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CRSSItem;

@interface TrackInfo : NSObject
{
    @public
    NSString *title;
    NSString *artist;
    NSString *url;
    float duration;
    CRSSItem *pItem;
}

@end
