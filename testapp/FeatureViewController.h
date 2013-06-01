//
//  FeatureViewController.h
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RSSFeed.h"


@interface FeatureViewController : UITableViewController

@property (strong, nonatomic) id detailItem;

- (void)setFeed:(RSSFeed *)feed;
- (void)updateFeed;

@end
