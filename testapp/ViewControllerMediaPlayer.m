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
    AVAudioPlayer *m_audioPlayer;
    NSMutableArray *m_audioItems;
    bool m_isPlaying;
    bool m_autoPlay;
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
    m_isPlaying = false;
    m_autoPlay = false;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewRSSFeed:)
                                                 name:@"NewRSSFeed"
                                               object:nil];
    m_audioItems = [[NSMutableArray alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onNext:(id)sender
{
    if (m_audioItems.count > 0)
    {
        currentItem++;
        if (currentItem >= (m_audioItems.count-1))
        {
            currentItem = 0;
        }

        CRSSItem *rssItem = m_audioItems[currentItem];
        currentImage.image = rssItem.appIcon;

        [self prepareMusic];
    }
}

- (IBAction)onPrev:(id)sender
{
    if (m_audioItems.count > 0)
    {
        currentItem--;
        if (currentItem < 0)
        {
            currentItem = (m_audioItems.count-1);
        }
        
        CRSSItem *rssItem = m_audioItems[currentItem];
        currentImage.image = rssItem.appIcon;
        
        [self prepareMusic];
    }
}

- (void) receiveNewRSSFeed:(NSNotification *) notification
{
    RSSFeed *feed = [RSSFeed getInstance];

    [m_audioItems removeAllObjects];
    for (CRSSItem *item in feed.items)
    {
        if (item.mediaURLString)
        {
            [m_audioItems insertObject:item atIndex:0];
        }
    }

    if ((m_audioItems.count > 0) && currentImage)
    {
        CRSSItem *rssItem = m_audioItems[0];
        currentImage.image = rssItem.appIcon;
        [self prepareMusic];
    }

}
- (IBAction)toggleAutoPlay:(id)sender
{
    m_autoPlay = !m_autoPlay;
    
    UIButton *senderBtn = (UIButton*) sender;
    [senderBtn setSelected:m_autoPlay];
}

- (void) prepareMusic
{
    if (currentItem < m_audioItems.count)
    {
        CRSSItem *item = m_audioItems[currentItem];
        
        NSString* resourcePath = item.mediaURLString; //your url
        NSError *error;
        NSData *_objectData = [NSData dataWithContentsOfURL:[NSURL URLWithString:resourcePath]];
        m_audioPlayer = [[AVAudioPlayer alloc] initWithData:_objectData error:&error];
        m_audioPlayer.numberOfLoops = 0;
        m_audioPlayer.volume = 5.0f;  //set volume here
        m_audioPlayer.delegate = self;
        [m_audioPlayer prepareToPlay];
        
        if (m_isPlaying)
        {
            [m_audioPlayer play];
        }
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (m_autoPlay)
    {
        [self onNext:0];
    }
    else
    {
        [toolbarDragger setSelected:FALSE];
        m_isPlaying = false;
    }
}

- (IBAction)togglePlay:(id)sender
{
    if (m_audioPlayer)
    {
        if ([m_audioPlayer isPlaying])
        {
            [m_audioPlayer pause];
            [toolbarDragger setSelected:FALSE];
            m_isPlaying = false;
        }
        else
        {
            [m_audioPlayer play];
            [toolbarDragger setSelected:TRUE];
            m_isPlaying = true;
        }
    }
}


@end
