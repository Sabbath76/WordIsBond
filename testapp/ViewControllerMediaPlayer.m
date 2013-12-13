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
    AVAudioPlayer *m_audioPlayer;
    AVQueuePlayer *m_player;
    NSMutableArray *m_audioItems;
    NSURLConnection *m_currentConnection;
    float midOffset;
    float bottomOffset;
    int currentItem;
    int currentTrack;
    bool m_isPlaying;
    bool m_autoPlay;
    __weak IBOutlet UIToolbarDragger *btnPlay;
    __weak IBOutlet UISlider *sldrPosition;
    __weak IBOutlet UIButton *miniImage;
    
    __weak IBOutlet UIActivityIndicatorView *m_playSpinner;
//    UIActivityIndicatorView *m_spinner;
}

@end

@implementation ViewControllerMediaPlayer

@synthesize currentImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        if (btnPlay)
        {
            btnPlay.owningView = [self view];
        }
    }
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead"];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];
    

    
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self->bottomOffset = 47;
    self->midOffset = 149;

    float parentHeight = self.view.superview.superview.frame.origin.y + self.view.superview.superview.frame.size.height;
    CGRect rect = self.view.superview.frame;
    rect.origin.y = parentHeight - self->bottomOffset;
//    rect.origin.y = rect.size.height - self->bottomOffset;
    self.view.superview.frame = rect;
    
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

    if (btnPlay)
    {
        UIView *thisView = self.view;
        btnPlay.owningView = thisView;
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
    float parentHeight = self.view.superview.superview.frame.size.height;
    CGRect rect = self.view.superview.frame;
    rect.origin.y = parentHeight - self->bottomOffset;
    self.view.superview.frame = rect;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setItem:(CRSSItem *) rssItem
{
    [rssItem requestImage:self];
    currentImage.image = rssItem.blurredImage;
    [miniImage setImage:rssItem.appIcon forState:UIControlStateNormal];
    [miniImage setImage:rssItem.appIcon forState:UIControlStateSelected];
    _labelTitle.text = rssItem.title;
    [_tableView reloadData];

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

            CRSSItem *rssItem = m_audioItems[currentItem];
            currentTrack = rssItem.tracks.count - 1;
            [rssItem requestImage:self];
            currentImage.image = rssItem.blurredImage;
            [miniImage setImage:rssItem.appIcon forState:UIControlStateNormal];
            [miniImage setImage:rssItem.appIcon forState:UIControlStateSelected];
            _labelTitle.text = rssItem.title;
            [_tableView reloadData];

        }
        
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
    }
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

        [m_playSpinner setHidden:false];
//        m_spinner.frame = btnPlay.frame;
        [btnPlay setHidden:true];
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
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
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
        
 /*       NSError *error;
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
        }*/
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

    CRSSItem *newItem = m_audioItems[newTrack.itemID];
    bool itemChanged = newTrack.itemID != currentItem;
    
    currentItem = newTrack.itemID;
    currentTrack = newTrack.trackID;
    if (itemChanged)
    {
        [newItem requestImage:self];
        currentImage.image = newItem.blurredImage;
        [miniImage setImage:newItem.appIcon forState:UIControlStateNormal];
        [miniImage setImage:newItem.appIcon forState:UIControlStateSelected];
        _labelTitle.text = newItem.title;
        [_tableView reloadData];
    }
  
    //--- Queue up the next track
    TrackInfo *nextTrack = [self getNextTrack];
    if (nextTrack)
    {
        [self streamData:nextTrack->url];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                              selector:@selector(playerItemDidReachEnd:)
                                              name:AVPlayerItemDidPlayToEndTimeNotification object:[m_player currentItem]];
    }
    
    [self updateTracks];
    
    //--- Update control centre display
    TrackInfo *curTrack = newItem.tracks[currentTrack];
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    [songInfo setObject:curTrack->title forKey:MPMediaItemPropertyTitle];
    [songInfo setObject:newItem.title forKey:MPMediaItemPropertyArtist];
    [songInfo setObject:newItem.title forKey:MPMediaItemPropertyAlbumTitle];
    [songInfo setObject:[NSNumber numberWithFloat:curTrack->duration] forKey:MPMediaItemPropertyPlaybackDuration];
    [songInfo setObject:[NSNumber numberWithInt:1] forKey:MPNowPlayingInfoPropertyPlaybackRate];
    
    if ([newItem appIcon] != nil)
    {
        MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: [newItem appIcon]];
        [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    }
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    
//    [m_player removeItem:[m_player items][0]];
//    int count = [m_player items].count;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    //allow for state updates, UI changes
    [self onNextTrack];

}


- (void)setTrack:(int)newTrack
{
    currentTrack = newTrack;
    [self prepareMusic];
//    [self updateTracks];
}

- (TrackInfo *)getNextTrack
{
    struct STrackIdx newTrack = [self getNextTrackIdx];
    CRSSItem *item = m_audioItems[newTrack.itemID];
    return item.tracks[newTrack.trackID];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    CRSSItem *item = m_audioItems[currentItem];
    currentTrack++;
    if (currentTrack < item.tracks.count)
    {
        [self setTrack:currentTrack];
    }
    else if (m_autoPlay)
    {
        [self onNext:0];
    }
    else
    {
        [btnPlay setSelected:FALSE];
        m_isPlaying = false;
    }
}

- (IBAction)onPlayList:(id)sender
{
    UIView *moveView = self.view.superview;
    if (moveView)
    {
        CGRect parentFrame = moveView.superview.frame;
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
            moveView.frame = CGRectMake(moveView.frame.origin.x, parentFrame.size.height - midOffset,
                                        moveView.frame.size.width, moveView.frame.size.height);
            [UIView commitAnimations];
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

            [btnPlay setSelected:m_isPlaying];
            [self updateTracks];
        }
    }
}

- (IBAction)togglePlay:(id)sender
{
    if (btnPlay.isDragging == false)
    {
        [self setPlaying:!m_isPlaying];
    }
}


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
}


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
                    [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateNormal];
                    [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateSelected];
                    [btnPlay setHidden:false];

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
                    [btnPlay setImage:[UIImage imageNamed:@"player_play_off"] forState:UIControlStateNormal];
                    [btnPlay setImage:[UIImage imageNamed:@"player_play_on"] forState:UIControlStateSelected];
                    [btnPlay setHidden:false];

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


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if(connection == m_currentConnection)
    {
        //Reset the data as this could be fired if a redirect or other response occurs
        [m_receivedData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == m_currentConnection)
    {
        //Append the received data each time this is called
        [m_receivedData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (connection == m_currentConnection)
    {
    NSError *error;
    @try
    {
        m_audioPlayer = [[AVAudioPlayer alloc] initWithData:m_receivedData error:&error];
        
        if (error)
        {
            NSLog(@"%@", [error localizedDescription]);
        }
        m_audioPlayer.numberOfLoops = 0;
        m_audioPlayer.volume = 5.0f;  //set volume here
        m_audioPlayer.delegate = self;
        [m_audioPlayer prepareToPlay];

        [btnPlay.layer removeAllAnimations];
        if (m_audioPlayer)
        {
            [btnPlay setImage:[UIImage imageNamed:@"player_play_off"] forState:UIControlStateNormal];
            [btnPlay setImage:[UIImage imageNamed:@"player_play_on"] forState:UIControlStateSelected];
            
            CRSSItem *item = m_audioItems[currentItem];
            TrackInfo *trackInfo = item.tracks[currentTrack];
            trackInfo->duration = [m_audioPlayer duration];
            
            UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead"];
            [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
            [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];
            
            sldrPosition.maximumValue = [m_audioPlayer duration];
            sldrPosition.value = 0.0;
            
            [self updateTracks];
        }
        else
        {
            [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateNormal];
            [btnPlay setImage:[UIImage imageNamed:@"icon_opt"] forState:UIControlStateSelected];
            
            UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_off"];
            [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
            [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];
        }

        if (m_isPlaying)
        {
            [m_audioPlayer play];
            
            float duration = [m_audioPlayer duration];

            [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [sldrPosition setValue:0.0];
  //          }];
            }              completion:^(BOOL finished) {
                [UIView animateWithDuration:duration-0.1 animations:^{
                    [sldrPosition setValue:duration];
                }];
            }];

//            [sldrPosition.layer removeAllAnimations];
//            [sldrPosition setValue:0.0];
//            [UIView animateWithDuration:m_audioPlayer.duration animations:^{
//                [sldrPosition setValue:m_audioPlayer.duration];
//            }];
        }
    }
    @catch (NSException *exception)
    {
    }
    }
}

//--- Tracks list

- (IBAction)slideTIme:(id)sender
{
    if (m_player)
    {
        [m_player seekToTime:CMTimeMakeWithSeconds(sldrPosition.value, 10)];
    }
    if (m_audioPlayer)
    {
        m_audioPlayer.currentTime = sldrPosition.value;
        
//        [UIView animateWithDuration:m_audioPlayer.duration-m_audioPlayer.currentTime animations:^{
//            [sldrPosition setValue:m_audioPlayer.duration];
//        }];
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

- (void) updateTracks
{
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    CRSSItem *curItem = m_audioItems[currentItem];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        if (indexPath.section == 0)
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            UIImageView *imgView = (UIImageView *)[cell viewWithTag:4];
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
            imgView.image = [self getImageForTrack:indexPath.row];
            [imgView.layer removeAllAnimations];

        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ((section == 0) && (m_audioItems.count > 0))
    {
        CRSSItem *curItem = m_audioItems[currentItem];
        return curItem.tracks.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (m_audioItems.count > 0)
    {
        CRSSItem *curItem = m_audioItems[currentItem];
        
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
        imgView.image = [self getImageForTrack:indexPath.row];

        return cell;
    }
    
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setTrack:indexPath.row];
}


@end
