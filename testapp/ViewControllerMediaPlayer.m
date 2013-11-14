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
    NSMutableData *m_receivedData;
    AVAudioPlayer *m_audioPlayer;
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
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_off"];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self->bottomOffset = 47;
    self->midOffset = 149;

    float parentHeight = self.view.superview.superview.frame.size.height;
    CGRect rect = self.view.superview.frame;
    rect.origin.y = parentHeight - self->bottomOffset;
//    rect.origin.y = rect.size.height - self->bottomOffset;
    self.view.superview.frame = rect;
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
    m_audioItems = [[NSMutableArray alloc] init];
    
    _labelTitle.textColor = [UIColor grayColor];
    
    UIImage *sliderThumb = [UIImage imageNamed:@"player_playhead_off"];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateNormal];
    [sldrPosition setThumbImage:sliderThumb forState:UIControlStateHighlighted];

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
    currentImage.image = [rssItem requestImage:self];
    _labelTitle.text = rssItem.title;
    [_tableView reloadData];

    currentTrack = 0;
    [self prepareMusic];
}

- (IBAction)onNext:(id)sender
{
    if (m_audioItems.count > 0)
    {
        currentItem++;
        if (currentItem >= m_audioItems.count)
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
        
        TrackInfo *trackInfo = item.tracks[currentTrack];

        NSString* resourcePath = trackInfo ? trackInfo->url : item.mediaURLString;
        
        [btnPlay setImage:[UIImage imageNamed:@"streaming"] forState:UIControlStateNormal];
        [btnPlay setImage:[UIImage imageNamed:@"streamingOn"] forState:UIControlStateSelected];

        CABasicAnimation *fullRotation = [CABasicAnimation animationWithKeyPath: @"transform.rotation"];
        fullRotation.fromValue = [NSNumber numberWithFloat:0];
        fullRotation.toValue = [NSNumber numberWithFloat:((360*M_PI)/180)];
        fullRotation.duration = 0.5;
        fullRotation.repeatCount = INFINITY;
        [btnPlay.layer addAnimation:fullRotation forKey:@"360"];

        
        [self streamData:resourcePath];
        
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

- (void)setTrack:(int)newTrack
{
    currentTrack = newTrack;
    [self prepareMusic];
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


- (IBAction)togglePlay:(id)sender
{
    if (btnPlay.isDragging == false)
    {
        if (m_audioPlayer)
        {
            if ([m_audioPlayer isPlaying])
            {
                [m_audioPlayer pause];
                [btnPlay setSelected:FALSE];
                m_isPlaying = false;
                _labelTitle.textColor = [UIColor grayColor];
            }
            else
            {
                [m_audioPlayer play];
                [btnPlay setSelected:TRUE];
                m_isPlaying = true;
                _labelTitle.textColor = [UIColor whiteColor];

                [sldrPosition.layer removeAllAnimations];
                [sldrPosition setValue:m_audioPlayer.currentTime];
                [UIView animateWithDuration:m_audioPlayer.duration-m_audioPlayer.currentTime animations:^{
                    [sldrPosition setValue:m_audioPlayer.currentTime];
                }];

            }
            
            [self updateTracks];
        }
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
    m_receivedData = [[NSMutableData alloc] init];
    
    if (m_currentConnection)
    {
        [m_currentConnection cancel];
    }
    //Create the connection with the string URL and kick it off
    m_currentConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
    [m_currentConnection start];
    //    NSURLConnection
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
            [btnPlay setImage:[UIImage imageNamed:@"simplePlay"] forState:UIControlStateNormal];
            [btnPlay setImage:[UIImage imageNamed:@"simplePlayOn"] forState:UIControlStateSelected];
            
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
        return [UIImage imageNamed:@"simplePlayOn"];
    }
    else if (currentTrack == trackID)
    {
        return [UIImage imageNamed:@"simplePlay"];
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
                lblDuration.text = [NSString stringWithFormat:@"%d:%d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
            }
            imgView.image = [self getImageForTrack:indexPath.row];
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
            lblDuration.text = [NSString stringWithFormat:@"%d:%d", (int)(trackInfo->duration / 60.0f), (int)(trackInfo)%60];
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
