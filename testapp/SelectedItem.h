//
//  SelectedItem.h
//  WordIsBond
//
//  Created by Jose Lopes on 20/11/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRSSItem.h"

@interface SelectedItem : NSObject
{
    @public
    CRSSItem *item;
    bool isFavourite;
}

@end
