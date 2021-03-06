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

@interface MediaTrackController : UIViewController <IconDownloaderDelegate>
{
	NSInteger pageIndex;
	BOOL textViewNeedsUpdate;
	__weak IBOutlet UILabel *label;
    __weak IBOutlet UILabel *dateView;
    __weak IBOutlet UILabel *author;
    __weak IBOutlet UILabel *artist;
}

@property NSInteger pageIndex;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *blurredImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *streaming;

- (void)updateTextViews:(BOOL)force;
- (void)setSourceArray:(NSArray*)array;

@end

