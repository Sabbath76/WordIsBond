//
//  ViewControllerMediaPlayer.m
//  testapp
//
//  Created by Jose Lopes on 05/09/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "ViewControllerMediaPlayer.h"

#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>

#import "RSSFeed.h"
#import "CRSSItem.h"
#import "SelectedItem.h"

#import "MediaTrackController.h"


@interface ViewControllerMediaPlayer ()
{
    MediaTrackController *m_currentPage;
    MediaTrackController *m_nextPage;
    NSMutableData *m_receivedData;
    AVQueuePlayer *m_player;
    NSMutableArray *m_audioItems;
    NSMutableArray *m_audioTracks;
    NSURLConnection *m_currentConnection;
    NSArray *m_fullItems;
    NSArray *m_reducedItems;
    float m_slideInitialPos;
    float m_scrollStartPoint;
//    int currentItem;
    int currentTrack;
    bool m_isPlaying;
    bool m_autoPlay;
    
    id playbackObserver;
    
    __weak IBOutlet UIProgressView *m_trackProgress;
    __weak IBOutlet UIScrollView *m_scrollTrackHeader;
    __weak IBOutlet UIBarButtonItem *btnPlay;
    __weak IBOutlet UIBarButtonItem *btnPlay2;
    __weak IBOutlet UISlider *sldrPosition2;
    __weak IBOutlet UIButton *miniImage;
    __weak IBOutlet UIToolbar *toolbar;
    __weak IBOutlet UIToolbar *topToolbar;
    __weak IBOutlet UIView *m_playerDock;
    
    __weak IBOutlet UIBarButtonItem *m_currentTitle;
    __weak IBOutlet UILabel *m_labelCurTime;
    __weak IBOutlet UILabel *m_labelDuration;
    
    __weak IBOutlet UIActivityIndicatorView *m_playSpinner;
//    __weak IBOutlet NSLayoutConstraint *m_topConstraint;
    __weak NSLayoutConstraint *m_topConstraint;
//    UIActivityIndicatorView *m_spinner;
    __weak IBOutlet NSLayoutConstraint *m_toolbarContraint;
    
    int m_displayedTrack;
}

@end

@implementation ViewControllerMediaPlayer

@synthesize currentImage;

float bottomOffset  = 50;
float midOffset     = 149;
float topOffset     = 20;

float BLUR_IMAGE_RANGE = 100.0f;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_on"];
    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateHighlighted];
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

/*    UIView *myView = self.view.superview;
    UIView *parentView = myView.superview;
//    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:myView attribute:NSLayoutAttributeTop
//                                 relatedBy:NSLayoutRelationEqual toItem:parentView
//                                 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-bottomOffset];
//    [myView addConstraint:constraint];


    CGRect parentRect = parentView.frame;
    float parentHeight = parentRect.origin.y + parentRect.size.height;
    CGRect rect = myView.frame;
    rect.origin.y = parentHeight - self->bottomOffset;
//    rect.origin.y = rect.size.height - self->bottomOffset;
 ///   [UIView animateWithDuration:0.3f animations:^{[myView setFrame:rect];}];
//    myView.frame = rect;
    
    [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
    myView.frame = rect;
    [UIView commitAnimations];*/
    //Once the view has loaded then we can register to begin recieving controls and we can become the first responder
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    NSError *setCategoryError = nil;
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
    [[AVAudioSession sharedInstance] setDelegate:self];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    m_player = [[AVQueuePlayer alloc] init];
    m_player.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
    
    CMTime interval = CMTimeMake(33, 1000);
    __weak ViewControllerMediaPlayer *self_ = self;
    self->playbackObserver = [m_player addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time) {
        if (self_ != nil)
        {
            ViewControllerMediaPlayer *sself = self_;
            CMTime endTime = CMTimeConvertScale (sself->m_player.currentItem.asset.duration, sself->m_player.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
            Float64 currentSeconds = CMTimeGetSeconds(sself->m_player.currentTime);
//            if (CMTimeCompare(endTime, kCMTimeZero) != 0)
            {
                if ([sself->sldrPosition2 isTracking] == false)
                {
                    sself->sldrPosition2.value = currentSeconds;
                }
            }
            int mins = currentSeconds/60.0;
            int secs = fmodf(currentSeconds, 60.0);
            NSString *minsString = [NSString stringWithFormat:@"%d", mins];
            NSString *secsString = secs < 10 ? [NSString stringWithFormat:@"0%d", secs] : [NSString stringWithFormat:@"%d", secs];
            sself->m_labelCurTime.text = [NSString stringWithFormat:@"%@:%@", minsString, secsString];

            Float64 durationSeconds = CMTimeGetSeconds(endTime);
            Float64 timeTillEnd = durationSeconds - currentSeconds;
            mins = timeTillEnd/60.0;
            secs = fmodf(timeTillEnd, 60.0);
            minsString = [NSString stringWithFormat:@"%d", mins];
            secsString = secs < 10 ? [NSString stringWithFormat:@"0%d", secs] : [NSString stringWithFormat:@"%d", secs];
            sself->m_labelDuration.text = [NSString stringWithFormat:@"-%@:%@", minsString, secsString];
            
            if (CMTimeCompare(endTime, kCMTimeZero) != 0)
            {
                double normalizedTime = (double) sself->m_player.currentTime.value / (double) endTime.value;
                [sself->m_trackProgress setProgress:normalizedTime];
            }
        }
    }];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
    {
        topOffset = 20;
    }
    else
    {
        topOffset = 60;
    }

//    CGRect imageFrame = currentImage.frame;
//    CGRect toolFrame = m_playerDock.frame;
//    float headerBottom = (toolFrame.origin.y + toolFrame.size.height) - imageFrame.origin.y;
//    [self.tableView setContentInset:UIEdgeInsetsMake(headerBottom, 0, 0, 0)];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //End recieving events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    //if it is a remote control event handle it correctly
    if (event.type == UIEventTypeRemoteControl)
    {
        if (event.subtype == UIEventSubtypeRemoteControlPlay)
        {
            [self setPlaying:true];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPause)
        {
            [self setPlaying:false];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause)
        {
            [self setPlaying:!m_isPlaying];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlNextTrack)
        {
            [self onNext:self];
        }
        else if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack)
        {
            [self onPrev:self];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    currentTrack = 0;
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewRSSFeed:)
                                                 name:@"NewTrackInfo"
                                               object:nil];
    m_audioItems = [[NSMutableArray alloc] init];
    m_audioTracks = [[NSMutableArray alloc] init];
    
    _labelTitle.textColor = [UIColor grayColor];
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_on"];
    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateHighlighted];

    
    if (miniImage)
    {
        CALayer *_maskingLayer = [CALayer layer];
        _maskingLayer.frame = miniImage.bounds;
        UIImage *stretchableImage = (id)[UIImage imageNamed:@"cornerfull"];
        
        _maskingLayer.contents = (id)stretchableImage.CGImage;
        _maskingLayer.contentsScale = [UIScreen mainScreen].scale; //<-needed for the retina display, otherwise our image will not be scaled properly
        _maskingLayer.contentsCenter = CGRectMake(15.0/stretchableImage.size.width,15.0/stretchableImage.size.height,5.0/stretchableImage.size.width,5.0f/stretchableImage.size.height);
        
        [miniImage.layer setMask:_maskingLayer];
    }
    
    m_currentPage = [[MediaTrackController alloc] initWithNibName:@"MediaPlayerHeader" bundle:nil];
	m_nextPage = [[MediaTrackController alloc] initWithNibName:@"MediaPlayerHeader" bundle:nil];

    [m_scrollTrackHeader addSubview:m_currentPage.view];
	[m_scrollTrackHeader addSubview:m_nextPage.view];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveViewPost:)
                                                 name:@"ViewPost"
                                               object:nil];


//    UIView *myView = self.view.superview;
//    UIView *parentView = myView.superview;
//    [NSLayoutConstraint constraintWithItem:myView attribute:NSLayoutAttributeTop
//                                 relatedBy:NSLayoutRelationEqual toItem:parentView
//                                 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-bottomOffset];


//    m_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    [m_spinner startAnimating];
    
//    _bar.layer.masksToBounds = false;
//    _bar.layer.shadowOffset = CGSizeMake(0, 15);
//    _bar.layer.shadowRadius = 8;
//    _bar.layer.shadowOpacity = 0.5;
   
//    CGRect rect = self.view.superview.frame;
//    rect.origin.y = rect.size.height - 39;
//    self.view.superview.frame = rect;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
//    float parentHeight = self.view.superview.superview.frame.size.height;
//    CGRect rect = self.view.superview.frame;
//    rect.origin.y = parentHeight - self->bottomOffset;
//    self.view.superview.frame = rect;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*- (void)setItem:(CRSSItem *) rssItem
{
    [rssItem requestImage:self];
//    currentImage.image = rssItem.blurredImage;
//    [miniImage setImage:rssItem.appIcon forState:UIControlStateNormal];
//    [miniImage setImage:rssItem.appIcon forState:UIControlStateSelected];
//    _labelTitle.text = rssItem.title;
//    [_tableView reloadData];

    currentTrack = 0;
    [self prepareMusic];
}*/

- (IBAction)onNext:(id)sender
{
    if (m_audioTracks.count > 0)
    {
        [m_player advanceToNextItem];
        [self onNextTrack];
        
        [m_nextPage.streaming startAnimating];
        
/*        currentItem++;
        if (currentItem >= m_audioItems.count)
        {
            currentItem = 0;
        }

        CRSSItem *rssItem = m_audioItems[currentItem];
        [self setItem:rssItem];
*/    }
}

- (IBAction)onPrev:(id)sender
{
    if (m_audioTracks.count > 0)
    {
        if (currentTrack == 0)
        {
            currentTrack = m_audioTracks.count - 1;
        }
        else
        {
            currentTrack--;
        }

        [self updateCurrentTrack:currentTrack updateListItems:true];
        [self prepareMusic];
    }
}

- (void) receiveNewRSSFeed:(NSNotification *) notification
{
    RSSFeed *feed = [RSSFeed getInstance];

    for (CRSSItem *item in feed.items)
    {
        if ([item waitingOnTracks])
            return;
    }

    [m_audioItems removeAllObjects];
    [m_audioTracks removeAllObjects];
    for (CRSSItem *item in feed.items)
    {
        if (item.tracks)
        {
            [m_audioItems addObject:item];
            
            for (TrackInfo *trackInfo in item.tracks)
            {
                [m_audioTracks addObject:trackInfo];
            }
        }
        else if (item.mediaURLString)
        {
            [m_audioItems addObject:item];
        }
    }

    m_displayedTrack = 0;
    currentTrack = 0;
    if (m_audioTracks.count > 0)
    {
        [self prepareMusic];
        
        [self updateCurrentTrack:currentTrack updateListItems:false];
    }
    
    [self.tableView reloadData];
    
    if (m_currentPage)
    {
        [m_currentPage setSourceArray:m_audioTracks];
        [self applyNewIndex:currentTrack pageController:m_currentPage];
    }
    if (m_nextPage)
    {
        [m_nextPage setSourceArray:m_audioTracks];
        [self applyNewIndex:currentTrack+1 pageController:m_nextPage];
    }

    if (m_scrollTrackHeader)
    {
        int numItems = m_audioTracks ? m_audioTracks.count : 1;
        m_scrollTrackHeader.contentSize =
        CGSizeMake(
                   m_scrollTrackHeader.frame.size.width * numItems,
                   m_scrollTrackHeader.frame.size.height);
    }

    
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
/*    if (m_audioItems.count > 0)
    {
        if (((CRSSItem*)m_audioItems[currentItem]).postID == iconDownloader.postID)
        {
            currentImage.image = iconDownloader.appRecord.blurredImage;
            [miniImage setImage:iconDownloader.appRecord.appIcon forState:UIControlStateNormal];
            [miniImage setImage:iconDownloader.appRecord.appIcon forState:UIControlStateSelected];
        }
    }*/
    
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        TrackInfo *trackInfo = m_audioTracks[indexPath.row];
        CRSSItem *cellItem = trackInfo->pItem;
        if (cellItem.postID == iconDownloader.postID)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
            imgView.image = cellItem.iconImage;
        }
    }
}

- (void) onIconLoaded:(NSNotification *) notification
{
/*    CRSSItem *item = [[notification userInfo] valueForKey:@"item"];
    if (m_audioItems.count > 0)
    {
        if (m_audioItems[currentItem] == item)
        {
            currentImage.image = item.appIcon;
            [miniImage setImage:item.appIcon forState:UIControlStateNormal];
            [miniImage setImage:item.appIcon forState:UIControlStateSelected];
        }
    }*/
    
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        TrackInfo *trackInfo = m_audioTracks[indexPath.row];
        CRSSItem *cellItem = trackInfo->pItem;
        if (cellItem.postID == trackInfo->pItem.postID)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
            imgView.image = cellItem.iconImage;
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
    if (currentTrack < m_audioTracks.count)
    {
        TrackInfo *trackInfo = m_audioTracks[currentTrack];
        CRSSItem *item = trackInfo->pItem;
        
        NSString* resourcePath = trackInfo ? trackInfo->url : item.mediaURLString;

////        [m_playSpinner setHidden:false];
//        m_spinner.frame = btnPlay.frame;
 ////       [btnPlay setHidden:true];
//        [btnPlay addSubview:m_spinner];
//        [btnPlay setImage:nil forState:UIControlStateNormal];
//        [btnPlay setImage:nil forState:UIControlStateSelected];
//        [btnPlay setImage:[UIImage imageNamed:@"streaming"] forState:UIControlStateNormal];
//        [btnPlay setImage:[UIImage imageNamed:@"streamingOn"] forState:UIControlStateSelected];

/*        CABasicAnimation *fullRotation = [CABasicAnimation animationWithKeyPath: @"transform.rotation"];
        fullRotation.fromValue = [NSNumber numberWithFloat:0];
        fullRotation.toValue = [NSNumber numberWithFloat:((360*M_PI)/180)];
        fullRotation.duration = 0.5;
        fullRotation.repeatCount = INFINITY;
        [btnPlay.layer addAnimation:fullRotation forKey:@"360"];
*/
/*        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            if ((indexPath.section == 0) && (indexPath.row == currentTrack))
            {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
//                [imgView.layer addAnimation:fullRotation forKey:@"360"];
                imgView.image = m_isPlaying ? [UIImage imageNamed:@"streamingOn"] : [UIImage imageNamed:@"streaming"];
            }
        }
*/
        [m_currentPage.streaming startAnimating];
        [m_nextPage.streaming startAnimating];

        [m_player removeAllItems];
        [self streamData:resourcePath];
        TrackInfo *nextTrack = [self getNextTrack];
        if (nextTrack)
        {
            [self streamData:nextTrack->url];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification object:[m_player currentItem]];
        
/*
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
        [songInfo setObject:trackInfo->title forKey:MPMediaItemPropertyTitle];
        [songInfo setObject:item.title forKey:MPMediaItemPropertyArtist];
        [songInfo setObject:item.title forKey:MPMediaItemPropertyAlbumTitle];
        [songInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        if ([item appIcon] != nil)
        {
            MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: [item appIcon]];
            [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
        }
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
        
        m_currentTitle.title = trackInfo->title;
        self.labelTitle.text = trackInfo->title;
*/
     }
}

- (int) getNextTrackIdx
{
    return (currentTrack + 1)%m_audioTracks.count;
}

- (IBAction)onPostClick:(id)sender
{
    if (m_audioTracks)
    {
        UIView *moveView = self.view.superview;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        float max = screenRect.size.height - bottomOffset;
        [self setTopToolbarActive:true];
        [m_topConstraint setConstant:max];
        [UIView animateWithDuration:0.5f animations:^{[moveView layoutIfNeeded];}];

        SelectedItem *item = [SelectedItem alloc];
        item->isFavourite = false;
        TrackInfo *track = m_audioTracks[currentTrack];
        item->item = track->pItem;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ViewPost" object:item];
    }
}


- (void) receiveViewPost:(NSNotification *) notification
{
    UIView *moveView = self.view.superview;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float max = screenRect.size.height - bottomOffset;
    float min = topOffset;
    float threshold = (min+max)/2.0;
    
    bool isAtBottom = [m_topConstraint constant] > threshold;
    if (!isAtBottom)
    {
        [self setTopToolbarActive:true];
        [m_topConstraint setConstant:max];
        [UIView animateWithDuration:0.5f animations:^{[moveView layoutIfNeeded];}];
    }
}


- (void)onNextTrack
{
    //--- Update UI
    int newTrack = [self getNextTrackIdx];

    [self updateCurrentTrack:newTrack updateListItems:true];
/*    CRSSItem *newItem = m_audioItems[newTrack.itemID];
    bool itemChanged = newTrack.itemID != currentItem;
    
    currentItem = newTrack.itemID;
    currentTrack = newTrack.trackID;
    if (itemChanged)
    {
        [newItem requestImage:self];
        currentImage.image = newItem.blurredImage;
        [miniImage setImage:newItem.appIcon forState:UIControlStateNormal];
        [miniImage setImage:newItem.appIcon forState:UIControlStateSelected];
//        [_tableView reloadData];
    }*/


    //--- Queue up the next track
    TrackInfo *nextTrack = [self getNextTrack];
    if (nextTrack)
    {
        [self streamData:nextTrack->url];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(playerItemDidReachEnd:)
                                              name:AVPlayerItemDidPlayToEndTimeNotification object:[m_player currentItem]];
    }
    
//    [self updateTracks];
    
//    [m_player removeItem:[m_player items][0]];
//    int count = [m_player items].count;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    //allow for state updates, UI changes
    [self onNextTrack];

}

- (void)updateCurrentTrack:(int)track updateListItems:(Boolean)updateListItems
 {
    currentTrack = track;
    
    if (updateListItems)
    {
        if (m_displayedTrack != -1)
        {
            [self updateTrackCell:m_displayedTrack];
        }
        m_displayedTrack = currentTrack;
        [self updateTrackCell:m_displayedTrack];
        
        [m_scrollTrackHeader scrollRectToVisible:CGRectMake(m_scrollTrackHeader.frame.size.width*track, 0, m_scrollTrackHeader.frame.size.width , m_scrollTrackHeader.frame.size.height) animated:YES];
    }
    
    TrackInfo *trackInfo = m_audioTracks[currentTrack];
    CRSSItem *newItem = trackInfo->pItem;
    [newItem requestImage:self];
    currentImage.image = newItem.blurredImage;
    [miniImage setImage:newItem.appIcon forState:UIControlStateNormal];
    [miniImage setImage:newItem.appIcon forState:UIControlStateSelected];
    
    //--- Update trackInfo centre display
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    [songInfo setObject:trackInfo->title forKey:MPMediaItemPropertyTitle];
    [songInfo setObject:newItem.title forKey:MPMediaItemPropertyArtist];
    [songInfo setObject:newItem.title forKey:MPMediaItemPropertyAlbumTitle];
    [songInfo setObject:[NSNumber numberWithFloat:trackInfo->duration] forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    _labelTitle.text = trackInfo->title;
    
    if ([newItem appIcon] != nil)
    {
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: [newItem appIcon]];
        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    }
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

- (TrackInfo *)getNextTrack
{
    int newTrack = [self getNextTrackIdx];
    return m_audioTracks[newTrack];
}

- (void) setSlideConstraint:(NSLayoutConstraint*)constraint
{
    m_topConstraint = constraint;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float max = screenRect.size.height - bottomOffset;
    [m_topConstraint setConstant:max];
}

- (IBAction)onPlayList:(id)sender
{
    UIView *moveView = self.view.superview;
    if (moveView)
    {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        float min = topOffset;
        float max = screenRect.size.height - bottomOffset;
        float threshold = (min+max)/2.0;

        bool isAtBottom = [m_topConstraint constant] < threshold;
        [self setTopToolbarActive:isAtBottom];
        if (isAtBottom)
        {
            [m_topConstraint setConstant:max];
        }
        else
        {
            [m_topConstraint setConstant:min];
        }
        [UIView animateWithDuration:0.5f animations:^{[moveView layoutIfNeeded];}];
/*        CGRect parentFrame = moveView.superview.frame;
        if (moveView.frame.origin.y < (parentFrame.origin.y + (parentFrame.size.height - ((midOffset + bottomOffset) * 0.5))))
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, parentFrame.size.height - bottomOffset,
                                        moveView.frame.size.width, moveView.frame.size.height);
            
            [UIView commitAnimations];
        }
        else
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, parentFrame.origin.y,
                                        moveView.frame.size.width, parentFrame.size.height);
//            self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y,
//                                         self.view.frame.size.width, parentFrame.size.height);
            [UIView commitAnimations];
        }*/
    }
}

- (void) setPlaying:(bool)play
{
    if (m_isPlaying != play)
    {
        m_isPlaying = play;
    
        if (m_player)
        {
            if (m_isPlaying)
            {
                [m_player play];
            }
            else
            {
                [m_player pause];
            }

            [btnPlay setTintColor:m_isPlaying?[self getActiveColour]:[UIColor lightGrayColor]];
            [btnPlay2 setTintColor:m_isPlaying?[self getActiveColour]:[UIColor lightGrayColor]];
            [self updateTrackCell:m_displayedTrack];
        }
    }
}

- (IBAction)togglePlay:(id)sender
{
   [self setPlaying:!m_isPlaying];
 }

/*
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UIView *moveView = self.view.superview;
    if (moveView)
    {
        UITouch *aTouch = [touches anyObject];
        CGPoint prevLocation = [aTouch previousLocationInView:moveView.superview];
        CGPoint location = [aTouch locationInView:moveView.superview];
        
        CGRect parentFrame = moveView.superview.frame;
        
        prevLocation.y = MAX(prevLocation.y, parentFrame.size.height - midOffset);
        prevLocation.y = MIN(prevLocation.y, parentFrame.size.height - bottomOffset);
        
        location.y = MAX(location.y, parentFrame.size.height - midOffset);
        location.y = MIN(location.y, parentFrame.size.height - bottomOffset);
        
        [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
        moveView.frame = CGRectMake(moveView.frame.origin.x, moveView.frame.origin.y + location.y - prevLocation.y,
                                    moveView.frame.size.width, moveView.frame.size.height);
        [UIView commitAnimations];
    }
    
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    UIView *moveView = self.view.superview;
    if (moveView)
    {
        CGRect parentFrame = moveView.superview.frame;
        
        if (moveView.frame.origin.y < (parentFrame.origin.y + (parentFrame.size.height / 2)))
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, 0,
                                        moveView.frame.size.width, moveView.frame.size.height);
            [UIView commitAnimations];
            
        }
        else if (moveView.frame.origin.y < (parentFrame.origin.y + (parentFrame.size.height - ((midOffset + bottomOffset) * 0.5))))
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, parentFrame.size.height - midOffset,
                                        moveView.frame.size.width, moveView.frame.size.height);
            [UIView commitAnimations];
        }
        else
        {
            [UIView beginAnimations:@"Dragging A DraggableView" context:nil];
            moveView.frame = CGRectMake(moveView.frame.origin.x, parentFrame.size.height - bottomOffset,
                                        moveView.frame.size.width, moveView.frame.size.height);
            [UIView commitAnimations];
        }
    }
}*/


- (void) streamData:(NSString *)url
{
    NSURL *streamURL = [NSURL URLWithString:url];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:streamURL];
    
    if (playerItem != nil)
    {
        [playerItem addObserver:self forKeyPath:@"status" options:0
                        context:nil];
        
        [m_player insertItem:playerItem afterItem:nil];
    }
    //m_player = [AVPlayer playerWithPlayerItem:playerItem];
    
/*
    
    m_receivedData = [[NSMutableData alloc] init];
    
    if (m_currentConnection)
    {
        [m_currentConnection cancel];
    }
    //Create the connection with the string URL and kick it off
    m_currentConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
    [m_currentConnection start];
    //    NSURLConnection*/
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[AVPlayerItem class]])
    {
        AVPlayerItem *item = (AVPlayerItem *)object;
        
        if (item == [m_player currentItem])
        {
        //playerItem status value changed?
        if ([keyPath isEqualToString:@"status"])
        {   //yes->check it...
            switch(item.status)
            {
                case AVPlayerItemStatusFailed:
                {
                    [m_playSpinner setHidden:true];
                    
                    [m_currentPage.streaming stopAnimating];
                    [m_nextPage.streaming stopAnimating];

//                    [m_spinner removeFromSuperview];

//                    [btnPlay.layer removeAllAnimations];
//                    [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateNormal];
//                    [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateSelected];
//                    [btnPlay setHidden:false];

                    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_on"];
                    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateNormal];
                    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateHighlighted];

                    NSLog(@"player item status failed");
                    
//////TODO                    [self onNextTrack];
                    break;
                }
                case AVPlayerItemStatusReadyToPlay:
                {
                    [m_playSpinner setHidden:true];

                    [m_currentPage.streaming stopAnimating];
                    [m_nextPage.streaming stopAnimating];

//                    [m_spinner removeFromSuperview];
//                    [btnPlay.layer removeAllAnimations];
//                    [btnPlay setImage:[UIImage imageNamed:@"player_play_off"] forState:UIControlStateNormal];
//                    [btnPlay setImage:[UIImage imageNamed:@"player_play_on"] forState:UIControlStateSelected];
//                    [btnPlay setHidden:false];

                    TrackInfo *trackInfo = m_audioTracks[currentTrack];
                    trackInfo->duration = CMTimeGetSeconds(item.duration);

                    if (m_isPlaying)
                    {
                        [m_player play];
                    }
                    [self updateTracks];

                    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_on"];
                    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateNormal];
                    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateHighlighted];
                    
                    sldrPosition2.maximumValue = trackInfo->duration;
                    sldrPosition2.value = 0.0f;
                    
                    m_labelCurTime.text = @"0:00";
                    m_labelDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];

//                    NSLog(@"player item status is ready to play");
                }
                    break;
                case AVPlayerItemStatusUnknown:
                    NSLog(@"player item status is unknown");
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (item.playbackBufferEmpty)
            {
                NSLog(@"player item playback buffer is empty");
            }
        }
        }
    }
}

//--- Tracks list

- (IBAction)slideTIme:(UISlider *)sender
{
    if (m_player)
    {
        [m_player seekToTime:CMTimeMakeWithSeconds(sender.value, 10)];
    }
}

- (UIImage *)getImageForTrack:(int) trackID
{
    if (m_isPlaying && (currentTrack == trackID))
    {
        return [UIImage imageNamed:@"player_play_on"];
    }
    else if (currentTrack == trackID)
    {
        return [UIImage imageNamed:@"player_play_off"];
    }
    else
    {
        return [UIImage imageNamed:@"player_playhead_off"];
    }
}

- (UIColor *) getActiveColour
{
    return [UIColor colorWithRed:1.0f green:0.5f blue:0.3f alpha:1.0f];
}

- (UIColor *)getTextColourForTrack:(int) trackID
{
    bool isCurrent = (trackID == currentTrack);
    if (m_isPlaying && isCurrent)
    {
        return [self getActiveColour];
    }
    else if (isCurrent)
    {
        return [UIColor lightGrayColor];
    }
    else
    {
        return [UIColor darkGrayColor];
    }
}

- (void) updateTrackCell:(int) trackIdx
{
//    TrackInfo *trackInfo = m_audioTracks[trackIdx];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:trackIdx inSection:0]];
    UILabel *lblTitle    = (UILabel*)[cell viewWithTag:1];
/*    UILabel *lblDuration = (UILabel*)[cell viewWithTag:2];
    if (trackInfo->duration == 0.0f)
    {
        lblDuration.text = @"--:--";
    }
    else
    {
        lblDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
    }
 */
    [lblTitle setTextColor:[self getTextColourForTrack:trackIdx]];
}

- (void) updateTracks
{
    //TODO!
/*    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    CRSSItem *curItem = m_audioItems[currentItem];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        if (indexPath.section == 0)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//            UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
            UILabel *lblTitle    = (UILabel*)[cell viewWithTag:1];
            UILabel *lblDuration = (UILabel*)[cell viewWithTag:2];
            TrackInfo *trackInfo = curItem.tracks[indexPath.row];
            if (trackInfo->duration == 0.0f)
            {
                lblDuration.text = @"--:--";
            }
            else
            {
                lblDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
            }
            //imgView.image = [self getImageForTrack:indexPath.row];
            [lblTitle setTextColor:[self getTextColourForTrack:indexPath.row]];
//            [imgView.layer removeAllAnimations];

        }
    }*/
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return m_audioTracks.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        TrackInfo *trackInfo = m_audioTracks[indexPath.row];
        CRSSItem *curItem = trackInfo->pItem;
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Track" forIndexPath:indexPath];
        UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
        UILabel *lblTitle    = (UILabel*)[cell viewWithTag:1];
        UILabel *lblArtist   = (UILabel*)[cell viewWithTag:2];
//        UILabel *lblDuration = (UILabel*)[cell viewWithTag:2];
        lblTitle.text = trackInfo->title;
        lblArtist.text = trackInfo->artist;
/*        if (trackInfo->duration == 0.0f)
        {
            lblDuration.text = @"--:--";
        }
        else
        {
            lblDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
        }*/
        imgView.image = [curItem requestIcon:self];
        [lblTitle setTextColor:[self getTextColourForTrack:indexPath.row]];

        return cell;
    }
    
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        [self updateCurrentTrack:indexPath.row updateListItems:true];
        [self prepareMusic];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    m_scrollStartPoint = 0;//scrollView.contentOffset.y;
}

- (void)applyNewIndex:(NSInteger)newIndex pageController:(MediaTrackController *)pageController
{
	NSInteger pageCount = m_audioTracks ? m_audioTracks.count : 1;
	BOOL outOfBounds = newIndex >= pageCount || newIndex < 0;
    
	if (!outOfBounds)
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = 0;
		pageFrame.origin.x = m_scrollTrackHeader.frame.size.width * newIndex;
		pageController.view.frame = pageFrame;
        
	    TrackInfo *trackInfo = m_audioTracks[newIndex];
        [trackInfo->pItem requestImage:self];
    }
	else
	{
		CGRect pageFrame = pageController.view.frame;
		pageFrame.origin.y = m_scrollTrackHeader.frame.size.height;
		pageController.view.frame = pageFrame;
	}
    
	pageController.pageIndex = newIndex;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (sender == m_scrollTrackHeader)
    {
        CGFloat pageWidth = m_scrollTrackHeader.frame.size.width;
        float fractionalPage = m_scrollTrackHeader.contentOffset.x / pageWidth;
        
        NSInteger lowerNumber = floor(fractionalPage);
        NSInteger upperNumber = lowerNumber + 1;
        
        if (lowerNumber == m_currentPage.pageIndex)
        {
            if (upperNumber != m_nextPage.pageIndex)
            {
                [self applyNewIndex:upperNumber pageController:m_nextPage];
            }
        }
        else if (upperNumber == m_currentPage.pageIndex)
        {
            if (lowerNumber != m_nextPage.pageIndex)
            {
                [self applyNewIndex:lowerNumber pageController:m_nextPage];
            }
        }
        else
        {
            if (lowerNumber == m_nextPage.pageIndex)
            {
                [self applyNewIndex:upperNumber pageController:m_currentPage];
            }
            else if (upperNumber == m_nextPage.pageIndex)
            {
                [self applyNewIndex:lowerNumber pageController:m_currentPage];
            }
            else
            {
                [self applyNewIndex:lowerNumber pageController:m_currentPage];
                [self applyNewIndex:upperNumber pageController:m_nextPage];
            }
        }
        
        [m_currentPage updateTextViews:NO];
        [m_nextPage updateTextViews:NO];
     }
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)sender
{
    if (sender == m_scrollTrackHeader)
    {
        CGFloat pageWidth = m_scrollTrackHeader.frame.size.width;
        float fractionalPage = m_scrollTrackHeader.contentOffset.x / pageWidth;
        NSInteger nearestNumber = lround(fractionalPage);
        
        if (m_currentPage.pageIndex != nearestNumber)
        {
            MediaTrackController *swapController = m_currentPage;
            m_currentPage = m_nextPage;
            m_nextPage = swapController;
        }

        if (nearestNumber == currentTrack+1)
        {
            [m_player advanceToNextItem];
            [self onNextTrack];
        }
        else if (nearestNumber != currentTrack)
        {
            [self updateCurrentTrack:nearestNumber updateListItems:true];
            [self prepareMusic];
        }
        
        [m_currentPage updateTextViews:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sender
{
    if (sender == m_scrollTrackHeader)
    {
        [self scrollViewDidEndScrollingAnimation:sender];
    }
}

-(void) setTopToolbarActive:(bool) active
{
    if (m_fullItems == nil)
    {
        self.labelTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.labelTitle.superview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//        self.labelTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        m_fullItems = [topToolbar items];
        m_reducedItems = @[m_fullItems[1], m_fullItems[2]];
    }
    
    topToolbar.items = active ? m_fullItems : m_reducedItems;
    [topToolbar updateConstraints];
}

float MP_ANIMATION_DURATION = 0.5f;
float MP_FAST_ANIMATION_DURATION = 0.1f;

- (IBAction)onDrag:(UIPanGestureRecognizer *)sender
{
    float vX = 0.0;
    float compare;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float min = topOffset;
    float max = screenRect.size.height - bottomOffset;
    float threshold = (min+max)/2.0;
    
    switch (sender.state)
    {
        case UIGestureRecognizerStateBegan:
            m_slideInitialPos = [m_topConstraint constant];
            break;
        case UIGestureRecognizerStateEnded:
        {
            vX = [m_topConstraint constant] + (MP_ANIMATION_DURATION/2.0)*[sender velocityInView:self.view].y;
            compare = vX;//view.transform.tx + vX;
            bool top = (compare < threshold);
            if (top)
            {
                [m_topConstraint setConstant:min];
            }
            else
            {
                [m_topConstraint setConstant:max];
            }

            [self setTopToolbarActive:!top];

            [UIView animateWithDuration:MP_ANIMATION_DURATION animations:^
            {
                [self.view.superview layoutIfNeeded];
            }];

            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            compare = m_slideInitialPos+[sender translationInView:self.view].y;
            compare = MAX(compare, min);
            compare = MIN(compare, max);

            [m_topConstraint setConstant:compare];

            [UIView animateWithDuration:MP_FAST_ANIMATION_DURATION animations:^{[self.view.superview layoutIfNeeded];}];
            break;
        }
            
        default:
            break;
    }
}

@end
