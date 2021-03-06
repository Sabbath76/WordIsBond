//
//  PageViewController.h
//  PagingScrollView
//
//  Created by Matt Gallagher on 24/01/09.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <UIKit/UIKit.h>
#import "IconDownloader.h"
#import "CRSSItem.h"

@interface FullPostController : UIViewController <IconDownloaderDelegate, PostRequestDelegate, UIScrollViewDelegate, UIWebViewDelegate>
{
	NSInteger pageIndex;
	BOOL textViewNeedsUpdate;
//	IBOutlet UILabel *label;
//    __weak IBOutlet UILabel *dateView;
//    __weak IBOutlet UILabel *author;
}

@property NSInteger pageIndex;
//@property (weak, nonatomic) IBOutlet UIImageView *imageView;
//@property (weak, nonatomic) IBOutlet UIImageView *blurredImage;

- (void)updateTextViews:(BOOL)force;
- (void)setSourceArray:(NSArray*)array;
- (void)setAlpha:(float)alpha;
- (void) goToComments;

@end

