//
//  FeatureCell.h
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSFeed.h"

@class DetailViewController;

@interface FeatureCell : UITableViewCell <UITableViewDataSource, UITableViewDelegate>
{
    int leftMostFeature;
}

@property (nonatomic, retain) IBOutlet UITableView *horizontalTableView;
@property (nonatomic, retain) IBOutlet UIImageView *imageView1;
@property (nonatomic, retain) IBOutlet UIImageView *imageView2;
@property (nonatomic, retain) IBOutlet UIImageView *imageView3;
@property (nonatomic, retain) IBOutlet UIImageView *imageView4;
@property (nonatomic, retain) RSSFeed *rssFeed;
@property (strong, nonatomic) DetailViewController *detailViewController;

- (void)updateFeed;

@end
