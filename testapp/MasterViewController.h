//
//  MasterViewController.h
//  testapp
//
//  Created by Jose Lopes on 30/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IconDownloader.h"

@class DetailViewController;

@interface MasterViewController : UITableViewController <IconDownloaderDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;
@property (nonatomic, retain) NSMutableDictionary *imageDownloadsInProgress;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnMenu;

- (void) setMenuOpen:(bool)state;
- (void) selectDetail:(CRSSItem *)item;

@end
