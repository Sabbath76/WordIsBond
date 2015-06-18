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

#import "ViewControllerTrackMenu.h"

#import "GAI.h"
#import "GAITracker.h"
#import "GAIDictionaryBuilder.h"

@interface ViewControllerMediaPlayer ()
{
    MediaTrackController *m_currentPage;
    MediaTrackController *m_nextPage;
    NSMutableData *m_receivedData;
    AVQueuePlayer *m_player;
    NSMutableArray *m_audioTracks;
    NSURLConnection *m_currentConnection;
    NSArray *m_fullItems;
    NSArray *m_reducedItems;
    float m_slideInitialPos;
    float m_scrollStartPoint;
    NSInteger currentTrack;
    bool m_isPlaying;
    bool m_autoPlay;
    bool m_autoScrolling;
    
    NSMutableArray *m_observedItems;
    
    id playbackObserver;
    
    __weak IBOutlet UIProgressView *m_trackProgress;
    __weak IBOutlet UIScrollView *m_scrollTrackHeader;
    __weak IBOutlet UIButton *btnPlay;
    __weak IBOutlet UIBarButtonItem *btnPlay2;
    __weak IBOutlet UISlider *sldrPosition2;
//    __weak IBOutlet UIButton *miniImage;
//    __weak IBOutlet UIToolbar *toolbar;
    __weak IBOutlet UIToolbar *topToolbar;
//    __weak IBOutlet UIView *m_playerDock;
    
//    __weak IBOutlet UIBarButtonItem *m_currentTitle;
    __weak IBOutlet UILabel *m_labelCurTime;
    __weak IBOutlet UILabel *m_labelDuration;
    
    __weak IBOutlet UIProgressView *m_progressBar;
    
//    __weak IBOutlet UIActivityIndicatorView *m_playSpinner;
    __weak NSLayoutConstraint *m_topConstraint;
//    __weak IBOutlet NSLayoutConstraint *m_toolbarContraint;
    
    NSInteger m_displayedTrack;
}

@end

@implementation ViewControllerMediaPlayer

@synthesize currentImage;

float bottomOffset  = 56;
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

    //Once the view has loaded then we can register to begin recieving controls and we can become the first responder
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(audioSessionInterrupted:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: [AVAudioSession sharedInstance]]; 
    
    NSError *categoryError = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:&categoryError];
    
    if (categoryError) {
        NSLog(@"Error setting category! %@", [categoryError description]);
    }
    
    //activation of audio session
    NSError *activationError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setActive: YES error: &activationError];
    if (!success) {
        if (activationError) {
            NSLog(@"Could not activate audio session. %@", [activationError localizedDescription]);
        } else {
            NSLog(@"audio session could not be activated!");
        }
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //End recieving events
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
//    [m_player removeTimeObserver:self->playbackObserver];
}

//Make sure we can recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - notifications
-(void)audioSessionInterrupted:(NSNotification*)interruptionNotification
{
    NSLog(@"interruption received: %@", interruptionNotification);
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
    m_autoScrolling = false;
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
    {
        topOffset = 20;
    }
    else
    {
        topOffset = 60;
    }

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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCloseMediaPlayer:)
                                                 name:@"CloseMediaPlayer"
                                               object:nil];
    m_audioTracks = [[NSMutableArray alloc] init];
    
    _labelTitle.textColor = [UIColor grayColor];
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_on"];
    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateHighlighted];

    [self.tableView setContentInset:UIEdgeInsetsMake(145, 0, 0, 0)];
    
    m_currentPage = [[MediaTrackController alloc] initWithNibName:@"MediaPlayerHeader" bundle:nil];
	m_nextPage = [[MediaTrackController alloc] initWithNibName:@"MediaPlayerHeader" bundle:nil];

    [m_scrollTrackHeader addSubview:m_currentPage.view];
	[m_scrollTrackHeader addSubview:m_nextPage.view];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveViewPost:)
                                                 name:@"ViewPost"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPlayItem:)
                                                 name:@"PlayItem"
                                               object:nil];
    
    m_observedItems = [[NSMutableArray alloc] init];
    
    [self receiveNewRSSFeed:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onNext:(id)sender
{
    if (m_audioTracks.count > 0)
    {
        AVPlayerItem *playerItem = [m_player currentItem];
        if([m_observedItems containsObject:playerItem])
        {
            [playerItem removeObserver:self forKeyPath:@"status"];
            [m_observedItems removeObject:playerItem];
        }
        [m_player advanceToNextItem];
        [self onNextTrack];
        
        [m_nextPage.streaming startAnimating];
    }
}

- (IBAction)onPrev:(id)sender
{
    if (m_audioTracks.count > 0)
    {
        Float64 skipToStartTime = 5.0;
        
        //--- Rewind to start of current
        Float64 currentSeconds = CMTimeGetSeconds(m_player.currentTime);
        if (currentSeconds > skipToStartTime)
        {
            [m_player seekToTime:CMTimeMakeWithSeconds(0.0, 10)];
        }
        else
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
}



- (void) onCloseMediaPlayer:(NSNotification *) notification
{
    [self setOpen:false];
}

- (Boolean) hasTrackForId: (NSInteger) id
{
    for (TrackInfo *pCurTrackInfo in m_audioTracks)
    {
        if (pCurTrackInfo->pItem.postID == id)
        {
            return true;
        }
    }
    
    return false;
}

- (void) receiveNewRSSFeed:(NSNotification *) notification
{
    RSSFeed *feed = [RSSFeed getInstance];
    
    if (feed.reset)
    {
        [m_audioTracks removeAllObjects];
    }

    for (CRSSItem *item in feed.items)
    {
        if ([item waitingOnTracks])
            return;
    }
    
    Boolean hadTracks = m_audioTracks.count > 0;

    for (CRSSItem *item in feed.items)
    {
        if (item.tracks && ![self hasTrackForId:item.postID])
        {
            for (TrackInfo *trackInfo in item.tracks)
            {
                [m_audioTracks addObject:trackInfo];
            }
        }
    }
    for (CRSSItem *item in feed.features)
    {
        if (item.tracks && ![self hasTrackForId:item.postID])
        {
            for (TrackInfo *trackInfo in item.tracks)
            {
                [m_audioTracks addObject:trackInfo];
            }
        }
    }

    if ((m_audioTracks.count > 0) && !hadTracks)
    {
        m_displayedTrack = 0;
        currentTrack = 0;
        [self prepareMusic];
        
        [self updateCurrentTrack:currentTrack updateListItems:true];
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
        NSUInteger numItems = m_audioTracks ? m_audioTracks.count : 1;
        m_scrollTrackHeader.contentSize =
        CGSizeMake(
                   m_scrollTrackHeader.frame.size.width * numItems,
                   m_scrollTrackHeader.frame.size.height);
    }
    [m_scrollTrackHeader reloadInputViews];

    
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
   
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
    if (!m_player)
    {
        m_player = [[AVQueuePlayer alloc] init];
        m_player.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
        
        CMTime interval = CMTimeMake(33, 1000);
        __weak ViewControllerMediaPlayer *self_ = self;
        self->playbackObserver = [m_player addPeriodicTimeObserverForInterval:interval queue:NULL usingBlock:^(CMTime time) {
            if (self_ != nil)
            {
                ViewControllerMediaPlayer *sself = self_;
                //            AVPlayerItem *curItem = sself->m_player.currentItem;
                //            AVAsset *curAsset = curItem.asset;
                //            bool playable = [curAsset isPlayable];
                //            CMTime endTime = CMTimeConvertScale (curAsset.duration, sself->m_player.currentTime.timescale, kCMTimeRoundingMethod_RoundHalfAwayFromZero);
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
                
                if (sself->m_audioTracks.count > 0)
                {
                    TrackInfo *trackInfo = sself->m_audioTracks[sself->currentTrack];
                    Float64 durationSeconds = trackInfo->duration;
                    //            Float64 durationSeconds = CMTimeGetSeconds(endTime);
                    Float64 timeTillEnd = durationSeconds - currentSeconds;
                    mins = timeTillEnd/60.0;
                    secs = fmodf(timeTillEnd, 60.0);
                    minsString = [NSString stringWithFormat:@"%d", mins];
                    secsString = secs < 10 ? [NSString stringWithFormat:@"0%d", secs] : [NSString stringWithFormat:@"%d", secs];
                    sself->m_labelDuration.text = [NSString stringWithFormat:@"-%@:%@", minsString, secsString];
                    
                    if (currentSeconds != 0.0f)
                    {
                        double normalizedTime = currentSeconds / durationSeconds;
                        [sself->m_trackProgress setProgress:normalizedTime];
                    }
                    /*            if (CMTimeCompare(endTime, kCMTimeZero) != 0)
                     {
                     double normalizedTime = (double) sself->m_player.currentTime.value / (double) endTime.value;
                     [sself->m_trackProgress setProgress:normalizedTime];
                     }
                     */
                }
            }
        }];
    }

    if (currentTrack < m_audioTracks.count)
    {
        TrackInfo *trackInfo = m_audioTracks[currentTrack];
        CRSSItem *item = trackInfo->pItem;
        
        NSLog(@"Prepare music: %@", trackInfo->title);

        
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

        for (AVPlayerItem *playerItem in [m_player items])
        {
            if([m_observedItems containsObject:playerItem])
            {
                [playerItem removeObserver:self forKeyPath:@"status"];
            }
        }
        [m_observedItems removeAllObjects];
        [m_player removeAllItems];
        [self streamData:resourcePath];
        TrackInfo *nextTrack = [self getNextTrack];
        if (nextTrack)
        {
            NSLog(@"Prepare music: Streaming %@", nextTrack->title);

            [self streamData:nextTrack->url];
        }
        
/*        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification object:[m_player currentItem]];
*/
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

- (NSInteger) getNextTrackIdx
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
        item->isFeature = false;
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


- (void) onPlayItem:(NSNotification *) notification
{
    CRSSItem *pItem = (CRSSItem *)notification.object;
    if (pItem)
    {
        NSInteger curItem = 0;
        for (TrackInfo *trackInfo in m_audioTracks)
        {
            if (trackInfo->pItem.postID == pItem.postID)
            {
                [self updateCurrentTrack:curItem updateListItems:true];
                [self prepareMusic];
                [self setPlaying:true];
                break;
            }
            
            curItem++;
        }

    }
}

- (void)onNextTrack
{
    //--- Update UI
    NSInteger newTrack = [self getNextTrackIdx];

    bool updateListItems = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
    [self updateCurrentTrack:newTrack updateListItems:updateListItems];

    TrackInfo *newTrackInfo = m_audioTracks[newTrack];
    NSLog(@"onNextTrack %@", newTrackInfo->title);

    //--- Queue up the next track
    TrackInfo *nextTrack = [self getNextTrack];
    if (nextTrack)
    {
        [self streamData:nextTrack->url];

        NSLog(@"onNextTrack %lu %@", (unsigned long)[m_player items].count, [m_player currentItem].description);
        NSLog(@"onNextTrack:Streaming %@", nextTrack->title);
        
/*        if ([m_player items].count > 1)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                  selector:@selector(playerItemDidReachEnd:)
                                                  name:AVPlayerItemDidPlayToEndTimeNotification object:[m_player items][1]];
        }*/
    }
    
//    [self updateTracks];
    
//    [m_player removeItem:[m_player items][0]];
//    int count = [m_player items].count;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    TrackInfo *curTrack = m_audioTracks[currentTrack];
    NSLog(@"playerItemDidReachEnd %@", curTrack->title);
    
    //allow for state updates, UI changes
    [self onNextTrack];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"TrackMenu"])
    {
        UIView *parentView =[sender superview];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell*)parentView.superview];
        
//        [self.view setAlpha:0.3f];
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        [[segue destinationViewController] setTrackItem:m_audioTracks[indexPath.row]];

//        CRSSItem *object = _feed.items[indexPath.row];
//        [[segue destinationViewController] setDetailItem:object list:_feed.items];
    }
}

- (void)updateCurrentTrack:(NSInteger)track updateListItems:(Boolean)updateListItems
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
        
        m_autoScrolling = true;
        [m_scrollTrackHeader scrollRectToVisible:CGRectMake(m_scrollTrackHeader.frame.size.width*track, 0, m_scrollTrackHeader.frame.size.width , m_scrollTrackHeader.frame.size.height) animated:YES];
    }
    
    TrackInfo *trackInfo = m_audioTracks[currentTrack];
    CRSSItem *newItem = trackInfo->pItem;
    [newItem requestImage:self];
    currentImage.image = newItem.blurredImage;
//    [miniImage setImage:newItem.appIcon forState:UIControlStateNormal];
//    [miniImage setImage:newItem.appIcon forState:UIControlStateSelected];
    
    //--- Update trackInfo centre display
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    [songInfo setObject:trackInfo->title forKey:MPMediaItemPropertyTitle];
     NSString *pArtist = trackInfo->artist;
     if (pArtist == nil)
     {
         pArtist = newItem.title;
     }
     
    [songInfo setObject:pArtist forKey:MPMediaItemPropertyArtist];
    [songInfo setObject:newItem.title forKey:MPMediaItemPropertyAlbumTitle];
    [songInfo setObject:[NSNumber numberWithFloat:trackInfo->duration] forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithFloat:0.0f] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songInfo setObject:[NSNumber numberWithInt:m_isPlaying] forKey:MPNowPlayingInfoPropertyPlaybackRate];
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
    NSInteger newTrack = [self getNextTrackIdx];
    return m_audioTracks[newTrack];
}

- (void) setSlideConstraint:(NSLayoutConstraint*)constraint
{
    m_topConstraint = constraint;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float max = screenRect.size.height - bottomOffset;
    [m_topConstraint setConstant:max];
}

- (void) setOpen:(bool)open
{
    UIView *moveView = self.view.superview;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    float min = topOffset;
    float max = screenRect.size.height - bottomOffset;

    [self setTopToolbarActive:!open];
    [m_topConstraint setConstant:open?min:max];
    [UIView animateWithDuration:0.5f animations:^{[moveView layoutIfNeeded];}];
}

- (IBAction)onPlayList:(id)sender
{
    UIView *moveView = self.view.superview.superview;
    if (moveView)
    {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        float min = topOffset;
        float max = screenRect.size.height - bottomOffset;
        float threshold = (min+max)/2.0;

        bool isAtBottom = [m_topConstraint constant] < threshold;
        [self setTopToolbarActive:isAtBottom];
        float newConstraint = (isAtBottom ? max : min);

        [m_topConstraint setConstant:newConstraint];
        [UIView animateWithDuration:0.5
                         animations:^{
                             [moveView layoutIfNeeded]; // Called on parent view
                         }];
        
        if (!isAtBottom)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:currentTrack inSection:0];
            [self.tableView scrollToRowAtIndexPath:indexPath
                                 atScrollPosition:UITableViewScrollPositionTop
                                         animated:YES];
        }
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
                id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                
                [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                                      action:@"button_press"  // Event action (required)
                                                                       label:@"play"          // Event label
                                                                       value:nil] build]];    // Event value
        
                [m_player play];
            }
            else
            {
                [m_player pause];
            }

            NSString *imageName = m_isPlaying ? @"player_pause_on" : @"player_play_off";
            UIImage *btnImage =[UIImage imageNamed:imageName];
            [btnPlay setImage:btnImage forState:UIControlStateNormal];

//            [btnPlay setTintColor:m_isPlaying?[self getActiveColour]:[UIColor lightGrayColor]];
//            UIBarButtonSystemItem *item = (UIBarButtonSystemItem *)btnPlay2;
            [btnPlay2 setImage:btnImage];
            [btnPlay2 setTintColor:m_isPlaying?[self getActiveColour]:[UIColor lightGrayColor]];
            [self updateTrackCell:m_displayedTrack];
        }
        
        NSMutableDictionary *currentlyPlayingTrackInfo = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds([m_player currentItem].duration)] forKey:MPMediaItemPropertyPlaybackDuration];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds([m_player currentTime])] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [currentlyPlayingTrackInfo setObject:[NSNumber numberWithInt:m_isPlaying] forKey:MPNowPlayingInfoPropertyPlaybackRate];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:currentlyPlayingTrackInfo];
    }
}

- (IBAction)togglePlay:(id)sender
{
   [self setPlaying:!m_isPlaying];
}

- (void) streamData:(NSString *)url
{
    NSURL *streamURL = [NSURL URLWithString:url];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:streamURL];
    
    if (playerItem != nil)
    {
        NSLog(@"streamData %@", url);

        [m_player insertItem:playerItem afterItem:nil];
        
        [playerItem addObserver:self forKeyPath:@"status" options:0
                        context:nil];
        [m_observedItems addObject:playerItem];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];

    }
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    if (m_isPlaying)
    {
        [player play];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[AVPlayerItem class]])
    {
        AVPlayerItem *item = (AVPlayerItem *)object;
        
        //playerItem status value changed?
        if ([keyPath isEqualToString:@"status"])
        {   //yes->check it...
            
            NSLog(@"observeValueForKeyPath %ld %@", (long)item.status, (item == [m_player currentItem]) ? @"latest" : @"different");
            
            if (item == [m_player currentItem])
            {
                switch(item.status)
                {
                    case AVPlayerItemStatusFailed:
                    {
//                        [m_playSpinner setHidden:true];
                        
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
//                        [m_playSpinner setHidden:true];

                        [m_currentPage.streaming stopAnimating];
                        [m_nextPage.streaming stopAnimating];

    //                    [m_spinner removeFromSuperview];
    //                    [btnPlay.layer removeAllAnimations];
    //                    [btnPlay setImage:[UIImage imageNamed:@"player_play_off"] forState:UIControlStateNormal];
    //                    [btnPlay setImage:[UIImage imageNamed:@"player_play_on"] forState:UIControlStateSelected];
    //                    [btnPlay setHidden:false];

                        TrackInfo *trackInfo = m_audioTracks[currentTrack];
                        trackInfo->duration = CMTimeGetSeconds([item asset].duration);

                        if (m_isPlaying)
                        {
                            [m_player play];
                        }
//                        [self updateTracks];

                        UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_on"];
                        [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateNormal];
                        [sldrPosition2 setThumbImage:sliderThumb forState:UIControlStateHighlighted];
                        
                        sldrPosition2.maximumValue = trackInfo->duration;
                        sldrPosition2.value = 0.0f;
                        
                        m_labelCurTime.text = @"0:00";
                        m_labelDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
                        
                        [self updateCurrentTrack:currentTrack updateListItems:false];

    //                    NSLog(@"player item status is ready to play");
                    }
                        break;
                    case AVPlayerItemStatusUnknown:
                        NSLog(@"player item status is unknown");
                        break;
                }
            }
            [item removeObserver:self forKeyPath:@"status"];
            [m_observedItems removeObject:item];
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

//--- Tracks list

- (IBAction)slideTIme:(UISlider *)sender
{
    if (m_player)
    {
        [m_player seekToTime:CMTimeMakeWithSeconds(sender.value, 10)];
    }
}

- (UIImage *)getImageForTrack:(NSInteger) trackID
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
    return [UIColor colorWithRed:160.0f/256.0f green:72.0f/256.0f blue:51.0f/256.0f alpha:1.0f];
}

- (UIColor *)getTextColourForTrack:(NSInteger) trackID
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

- (UIImage *)getIconForTrack:(NSInteger) trackID
{
    bool isCurrent = (trackID == currentTrack);
    if (m_isPlaying && isCurrent)
    {
        return [UIImage imageNamed:@"player_play_on"];
    }
    else if (isCurrent)
    {
        return [UIImage imageNamed:@"player_play_off"];
    }
    else
    {
        TrackInfo *trackInfo = m_audioTracks[trackID];
        CRSSItem *curItem = trackInfo->pItem;
        
        return [curItem requestIcon:self];
    }
}

- (void) updateTrackCell:(NSInteger) trackIdx
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:trackIdx inSection:0]];
    UILabel *lblTitle    = (UILabel*)[cell viewWithTag:1];
    UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];

    imgView.image = [self getIconForTrack:trackIdx];
    [lblTitle setTextColor:[self getTextColourForTrack:trackIdx]];
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
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Track" forIndexPath:indexPath];
        UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
        UILabel *lblTitle    = (UILabel*)[cell viewWithTag:1];
        UILabel *lblArtist   = (UILabel*)[cell viewWithTag:2];
        lblTitle.text = trackInfo->title;
        lblArtist.text = trackInfo->artist;

        imgView.image = [self getIconForTrack:indexPath.row];// [curItem requestIcon:self];
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
        [self setPlaying:true];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    m_scrollStartPoint = 0;//scrollView.contentOffset.y;
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    UIView *touchView = touch.view;
    UIView *parentTouchView = touchView.superview;
    if ([touchView isKindOfClass:[UIControl class]]
        || [parentTouchView isKindOfClass:[UITableViewCell class]]
        || [parentTouchView isKindOfClass:[UITableView class]])
//       || [touchView isKindOfClass:[UITableViewCellContentView class]])
   {
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }

    return YES;
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
        if (!m_autoScrolling)
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
                AVPlayerItem *playerItem = [m_player currentItem];
                if([m_observedItems containsObject:playerItem])
                {
                    [playerItem removeObserver:self forKeyPath:@"status"];
                    [m_observedItems removeObject:playerItem];
                }

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
        m_autoScrolling = false;
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
    m_progressBar.hidden = !active;
    btnPlay.hidden = !active;
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
                [self.view.superview.superview layoutIfNeeded];
            }];

            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            compare = m_slideInitialPos+[sender translationInView:self.view].y;
            compare = MAX(compare, min);
            compare = MIN(compare, max);

            [m_topConstraint setConstant:compare];

            [UIView animateWithDuration:MP_FAST_ANIMATION_DURATION animations:^{[self.view.superview.superview layoutIfNeeded];}];
            break;
        }
            
        default:
            break;
    }
}

@end
