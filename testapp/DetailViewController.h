//
//  DetailViewController.h
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CRSSItem.h"
#import "GAITrackedViewController.h"

@interface DetailViewController : GAITrackedViewController <UISplitViewControllerDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnFavourite;

- (void)setDetailItem:(id)newDetailItem list:(NSArray *)sourceList;

@end
