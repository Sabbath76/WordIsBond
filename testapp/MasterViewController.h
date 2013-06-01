//
//  MasterViewController.h
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
