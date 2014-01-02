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

@interface ViewControllerMediaPlayer ()
{
    NSMutableData *m_receivedData;
    AVQueuePlayer *m_player;
    NSMutableArray *m_audioItems;
    NSURLConnection *m_currentConnection;
    NSArray *m_fullItems;
    NSArray *m_reducedItems;
    float m_slideInitialPos;
    float m_scrollStartPoint;
    int currentItem;
    int currentTrack;
    bool m_isPlaying;
    bool m_autoPlay;
    
    __weak IBOutlet UIBarButtonItem *btnPlay;
    __weak IBOutlet UIBarButtonItem *btnPlay2;
    __weak IBOutlet UISlider *sldrPosition;
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
    
    NSIndexPath *m_displayedTrack;
}

@end

@implementation ViewControllerMediaPlayer

@synthesize currentImage;

float bottomOffset  = 47;
float midOffset     = 149;
float topOffset     = 25;

float BLUR_IMAGE_RANGE = 100.0f;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead"];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];
    
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
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1)
    {
        topOffset = 8;
    }
    else
    {
        topOffset = 55;
    }

    CGRect imageFrame = currentImage.frame;
    CGRect toolFrame = m_playerDock.frame;
    float headerBottom = (toolFrame.origin.y + toolFrame.size.height) - imageFrame.origin.y;
    [self.tableView setContentInset:UIEdgeInsetsMake(headerBottom, 0, 0, 0)];
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
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNewRSSFeed:)
                                                 name:@"NewTrackInfo"
                                               object:nil];
    m_audioItems = [[NSMutableArray alloc] init];
    
    _labelTitle.textColor = [UIColor grayColor];
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead"];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];

    
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

- (void)setItem:(CRSSItem *) rssItem
{
    [rssItem requestImage:self];
/*    currentImage.image = rssItem.blurredImage;
    [miniImage setImage:rssItem.appIcon forState:UIControlStateNormal];
    [miniImage setImage:rssItem.appIcon forState:UIControlStateSelected];
    _labelTitle.text = rssItem.title;
    [_tableView reloadData];
*/
    currentTrack = 0;
    [self prepareMusic];
}

- (IBAction)onNext:(id)sender
{
    if (m_audioItems.count > 0)
    {
        [m_player advanceToNextItem];
        [self onNextTrack];
        
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
    if (m_audioItems.count > 0)
    {
        if (currentTrack > 0)
        {
            currentTrack--;
        }
        else
        {
            currentItem--;
            if (currentItem < 0)
            {
                currentItem = (m_audioItems.count-1);
            }
        }
        
        [self updateCurrentTrack:currentItem track:currentTrack];
        [self prepareMusic];
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
            [m_audioItems addObject:item];
        }
        else if (item.mediaURLString)
        {
            [m_audioItems addObject:item];
        }
    }

    currentItem = 0;
    if (m_audioItems.count > 0)
    {
        CRSSItem *rssItem = m_audioItems[0];
        [self setItem:rssItem];
        
        [self updateCurrentTrack:currentItem track:currentTrack];
    }
    
    [self.tableView reloadData];
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(IconDownloader *)iconDownloader
{
    if (m_audioItems.count > 0)
    {
        if (((CRSSItem*)m_audioItems[currentItem]).postID == iconDownloader.postID)
        {
            currentImage.image = iconDownloader.appRecord.blurredImage;
            [miniImage setImage:iconDownloader.appRecord.appIcon forState:UIControlStateNormal];
            [miniImage setImage:iconDownloader.appRecord.appIcon forState:UIControlStateSelected];
        }
    }
    
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        CRSSItem *cellItem = m_audioItems[indexPath.section];
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
    CRSSItem *item = [[notification userInfo] valueForKey:@"item"];
    if (m_audioItems.count > 0)
    {
        if (m_audioItems[currentItem] == item)
        {
            currentImage.image = item.blurredImage;
            [miniImage setImage:item.appIcon forState:UIControlStateNormal];
            [miniImage setImage:item.appIcon forState:UIControlStateSelected];
        }
    }
    
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        CRSSItem *cellItem = m_audioItems[indexPath.section];
        if (cellItem.postID == item.postID)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
            imgView.image = item.iconImage;
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
        
        TrackInfo *trackInfo = item.tracks[currentTrack];
        
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

struct STrackIdx
{
    int itemID;
    int trackID;
};

- (struct STrackIdx)getNextTrackIdx
{
    struct STrackIdx trackIdx;
    CRSSItem *item = m_audioItems[currentItem];
    if (currentTrack+1 < item.tracks.count)
    {
        trackIdx.itemID = currentItem;
        trackIdx.trackID = currentTrack+1;
    }
    else
    {
        trackIdx.itemID = (currentItem+1)%m_audioItems.count;
        trackIdx.trackID = 0;
    }
    
    return trackIdx;
}

- (IBAction)onPostClick:(id)sender
{
    if (m_audioItems)
    {
        SelectedItem *item = [SelectedItem alloc];
        item->isFavourite = false;
        item->item = m_audioItems[currentItem];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ViewPost" object:item];
    }
}

- (void)onNextTrack
{
    //--- Update UI
    struct STrackIdx newTrack = [self getNextTrackIdx];

    [self updateCurrentTrack:newTrack.itemID track:newTrack.trackID];
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

- (void)updateCurrentTrack:(int)item track:(int)track
{
    currentItem = item;
    currentTrack = track;
    
    if (m_displayedTrack != nil)
    {
        [self updateTrackCell:m_displayedTrack];
    }
    m_displayedTrack = [NSIndexPath indexPathForRow:currentTrack inSection:currentItem];
    [self updateTrackCell:m_displayedTrack];
    
    CRSSItem *newItem = m_audioItems[currentItem];
    [newItem requestImage:self];
    currentImage.image = newItem.blurredImage;
    [miniImage setImage:newItem.appIcon forState:UIControlStateNormal];
    [miniImage setImage:newItem.appIcon forState:UIControlStateSelected];
    
    //--- Update trackInfo centre display
    TrackInfo *trackInfo = newItem.tracks[currentTrack];
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
    struct STrackIdx newTrack = [self getNextTrackIdx];
    CRSSItem *item = m_audioItems[newTrack.itemID];
    return item.tracks[newTrack.trackID];
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
            [sldrPosition setHidden:false];
        }
        else
        {
            [m_topConstraint setConstant:min];
            [sldrPosition setHidden:true];
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
            [sldrPosition.layer removeAllAnimations];
            if (m_isPlaying)
            {
                [m_player play];
                
                AVPlayerItem *item = m_player.currentItem;
                
                float curTime = CMTimeGetSeconds(item.currentTime);
                float duration = CMTimeGetSeconds(item.duration);
                [sldrPosition setValue:curTime];
                [UIView animateWithDuration:duration-curTime animations:^{
                    [sldrPosition setValue:curTime];
                }];
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
    
    [playerItem addObserver:self forKeyPath:@"status" options:0
                    context:nil];
    
    [m_player insertItem:playerItem afterItem:nil];
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

//                    [m_spinner removeFromSuperview];

//                    [btnPlay.layer removeAllAnimations];
//                    [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateNormal];
//                    [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateSelected];
//                    [btnPlay setHidden:false];

                    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead"];
                    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
                    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];

                    NSLog(@"player item status failed");
                    
                    [self onNextTrack];
                    break;
                }
                case AVPlayerItemStatusReadyToPlay:
                {
                    [m_playSpinner setHidden:true];

//                    [m_spinner removeFromSuperview];
//                    [btnPlay.layer removeAllAnimations];
//                    [btnPlay setImage:[UIImage imageNamed:@"player_play_off"] forState:UIControlStateNormal];
//                    [btnPlay setImage:[UIImage imageNamed:@"player_play_on"] forState:UIControlStateSelected];
//                    [btnPlay setHidden:false];

                    CRSSItem *post = m_audioItems[currentItem];
                    TrackInfo *trackInfo = post.tracks[currentTrack];
                    trackInfo->duration = CMTimeGetSeconds(item.duration);

                    if (m_isPlaying)
                    {
                        [m_player play];
                    }
                    [self updateTracks];

                    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead"];
                    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
                    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];
                    
                    sldrPosition.maximumValue = trackInfo->duration;
                    sldrPosition.value = 0.0;
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

- (UIColor *)getTextColourForTrack:(NSIndexPath*) trackID
{
    bool isCurrent = (trackID.section == currentItem) && (trackID.row == currentTrack);
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

- (void) updateTrackCell:(NSIndexPath*) indexPath
{
    CRSSItem *curItem = m_audioItems[indexPath.section];
    TrackInfo *trackInfo = curItem.tracks[indexPath.row];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UILabel *lblTitle    = (UILabel*)[cell viewWithTag:1];
    UILabel *lblDuration = (UILabel*)[cell viewWithTag:2];
    if (trackInfo->duration == 0.0f)
    {
        lblDuration.text = @"--:--";
    }
    else
    {
        lblDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
    }
    [lblTitle setTextColor:[self getTextColourForTrack:indexPath]];
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
    return m_audioItems.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < m_audioItems.count)
    {
        CRSSItem *curItem = m_audioItems[section];
        return curItem.tracks.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < m_audioItems.count)
    {
        CRSSItem *curItem = m_audioItems[indexPath.section];
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Track" forIndexPath:indexPath];
        TrackInfo *trackInfo = curItem.tracks[indexPath.row];
        UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
        UILabel *lblTitle    = (UILabel*)[cell viewWithTag:1];
        UILabel *lblDuration = (UILabel*)[cell viewWithTag:2];
        lblTitle.text = trackInfo->title;
        if (trackInfo->duration == 0.0f)
        {
            lblDuration.text = @"--:--";
        }
        else
        {
            lblDuration.text = [NSString stringWithFormat:@"%d:%02d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
        }
        imgView.image = [curItem requestIcon:self];
        [lblTitle setTextColor:[self getTextColourForTrack:indexPath]];

        return cell;
    }
    
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateCurrentTrack:indexPath.section track:indexPath.row];
    [self prepareMusic];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    m_scrollStartPoint = 0;//scrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    float senderOffset  = m_scrollStartPoint-scrollView.contentOffset.y;
    float headerPos = m_playerDock.frame.size.height;

    float toolbarPos = MAX(senderOffset - headerPos, self.currentImage.frame.origin.y);
    [m_toolbarContraint setConstant:toolbarPos];
    
    float targetAlpha = 1.0f - MIN((toolbarPos - self.currentImage.frame.origin.y) / BLUR_IMAGE_RANGE, 1.0f);
    
    [UIView animateWithDuration:0.2f animations:^
     {
         [self.view layoutIfNeeded];
         [self.currentImage setAlpha:targetAlpha];
     }];
}

-(void) setTopToolbarActive:(bool) active
{
    [sldrPosition setHidden:active];
//    [btnPlay setHidden:active];

    if (m_fullItems == nil)
    {
        self.labelTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.labelTitle.superview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//        self.labelTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        m_fullItems = [topToolbar items];
        m_reducedItems = @[m_fullItems[3], m_fullItems[4], m_fullItems[5], m_fullItems[6]];
    }
    
    topToolbar.items = active ? m_fullItems : m_reducedItems;
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
                [sldrPosition setHidden:top];
//                [btnPlay setHidden:top];
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
