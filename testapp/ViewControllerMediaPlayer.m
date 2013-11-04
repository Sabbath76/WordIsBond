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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    CGRect rect = self.view.superview.frame;
    rect.origin.y = rect.size.height - 37;
    self.view.superview.frame = rect;
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onIconLoaded:)
                                                 name:@"IconLoaded"
                                               object:nil];
    m_audioItems = [[NSMutableArray alloc] init];
    
    _labelTitle.textColor = [UIColor grayColor];

//    _bar.layer.masksToBounds = false;
//    _bar.layer.shadowOffset = CGSizeMake(0, 15);
//    _bar.layer.shadowRadius = 8;
//    _bar.layer.shadowOpacity = 0.5;
   
//    CGRect rect = self.view.superview.frame;
//    rect.origin.y = rect.size.height - 39;
//    self.view.superview.frame = rect;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setItem:(CRSSItem *) rssItem
{
    currentImage.image = [rssItem requestImage:self];
    _labelTitle.text = rssItem.title;
    
    [self prepareMusic];
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
        [self setItem:rssItem];
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
        [self setItem:rssItem];
    }
}

- (void) receiveNewRSSFeed:(NSNotification *) notification
{
    RSSFeed *feed = [RSSFeed getInstance];

    [m_audioItems removeAllObjects];
    for (CRSSItem *item in feed.items)
    {
        if (item.tracks)
        {
            [m_audioItems insertObject:item atIndex:0];
        }
        else if (item.mediaURLString)
        {
            [m_audioItems insertObject:item atIndex:0];
        }
    }

    currentItem = 0;
    if (m_audioItems.count > 0)
    {
        CRSSItem *rssItem = m_audioItems[0];
        [self setItem:rssItem];
    }
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    if (m_audioItems.count > 0)
    {
        if (((CRSSItem*)m_audioItems[currentItem]).postID == iconDownloader.postID)
        {
            currentImage.image = iconDownloader.appRecord.appIcon;
        }
    }
}

- (void) onIconLoaded:(NSNotification *) notification
{
    CRSSItem *item = [[notification userInfo] valueForKey:@"item"];
    if (m_audioItems.count > 0)
    {
        if (m_audioItems[currentItem] == item)
        {
            currentImage.image = item.appIcon;
        }
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
        
        NSString* resourcePath = item.tracks ? item.tracks[0] : item.mediaURLString;
        NSError *error;
        NSData *_objectData = [NSData dataWithContentsOfURL:[NSURL URLWithString:resourcePath]];
        @try
        {
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
        @catch (NSException *exception)
        {
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

- (IBAction)onPlayList:(id)sender
{
}

- (IBAction)togglePlay:(id)sender
{
    if (toolbarDragger.isDragging == false)
    {
        if (m_audioPlayer)
        {
            if ([m_audioPlayer isPlaying])
            {
                [m_audioPlayer pause];
                [toolbarDragger setSelected:FALSE];
                m_isPlaying = false;
                _labelTitle.textColor = [UIColor grayColor];
            }
            else
            {
                [m_audioPlayer play];
                [toolbarDragger setSelected:TRUE];
                m_isPlaying = true;
                _labelTitle.textColor = [UIColor whiteColor];
            }
        }
    }
}


@end
