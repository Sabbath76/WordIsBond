//
//  ViewControllerMediaPlayer.m
//  testapp
//
//  Created by Jose Lopes on 05/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "ViewControllerMediaPlayer.h"

#import "RSSFeed.h"
#import "CRSSItem.h"

@interface ViewControllerMediaPlayer ()
{
    int currentItem;
}

@end

@implementation ViewControllerMediaPlayer

@synthesize toolbarDragger, currentImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        if (toolbarDragger)
        {
            toolbarDragger.owningView = [self view];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    if (toolbarDragger)
    {
        UIView *thisView = self.view;
        toolbarDragger.owningView = thisView;
    }
    currentItem = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewRSSFeed:)
                                                 name:@"NewRSSFeed"
                                               object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onNext:(id)sender
{
    RSSFeed *feed = [RSSFeed getInstance];
    if (feed)
    {
        currentItem++;
        if (currentItem >= (feed.features.count-1))
        {
            currentItem = 0;
        }

        CRSSItem *rssItem = feed.features[currentItem];
        currentImage.image = rssItem.appIcon;
    }
}

- (IBAction)onPrev:(id)sender
{
    RSSFeed *feed = [RSSFeed getInstance];
    if (feed)
    {
        currentItem--;
        if (currentItem < 0)
        {
            currentItem = (feed.features.count-1);
        }
        
        CRSSItem *rssItem = feed.features[currentItem];
        currentImage.image = rssItem.appIcon;
    }
}

- (void) receiveNewRSSFeed:(NSNotification *) notification
{
    RSSFeed *feed = [RSSFeed getInstance];

    if ((feed.features.count > 0) && currentImage)
    {
        CRSSItem *rssItem = feed.features[0];
        currentImage.image = rssItem.appIcon;
    }

}

@end
