//
//  CRSSItem.m
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "CRSSItem.h"
#import "UIImage+ImageEffects.h"

@implementation CRSSItem
{
    id<PostRequestDelegate> m_delegate;
    
    NSURLConnection *m_fullPostQuery;
    NSMutableData *m_receivedData;
    NSURLConnection *m_tracksQuery;
    NSMutableData *m_receivedDataTracks;
}

static NSString * BAND_CAMP_KEY = @"godsthannlitanpalafreyregna";
static NSString * BAND_CAMP_ALBUM_QUERY = @"http://api.bandcamp.com/api/album/2/info?key=godsthannlitanpalafreyregna&album_id=";
static NSString * BAND_CAMP_TRACK_URL = @"http://popplers5.bandcamp.com/download/track?enc=mp3-128&id=%@&stream=1";

@synthesize title, description, imageURLString, appIcon, mediaURLString, postID, requiresDownload, tracks, dateString, author, blurb, postURL, blurredImage;

- (NSString*) findProperty: (NSString *)search
{
    NSRange rangeOuter = [description rangeOfString:search];
    if (rangeOuter.location != NSNotFound)
    {
        NSRange rangeToSearchWithin = NSMakeRange(rangeOuter.location, description.length - rangeOuter.location);
        NSRange range = [description rangeOfString:@"src" options:0 range:rangeToSearchWithin];
        if (range.location != NSNotFound)
        {
            int startPos = range.location+range.length;
            NSString *subString = [description substringFromIndex:startPos];
            NSString *urlString;
            NSScanner *scanner = [NSScanner scannerWithString:subString];
            [scanner scanUpToString:@"\"" intoString:NULL];
            [scanner scanString:@"\"" intoString:NULL];
            [scanner scanUpToString:@"\"" intoString:&urlString];
            
            return urlString;
        }
    }

    return NULL;
}

- (CRSSItem *) init
{
    static int LAST_ID = 0;
    LAST_ID++;
    
    self.postID = LAST_ID;
    return self;
}

- (NSString *) convertWordPressString:(NSString*) inString
{
    struct SStringPair
    {
        __unsafe_unretained NSString *const symbol;
        __unsafe_unretained NSString *const value;
    };
    const int NUM_VALUES = 8;
    const struct SStringPair values[NUM_VALUES] = {{@"&#8211;", @"-"}, {@"&#8212;", @"--"}, {@"&#8230;", @"..."}, {@"&#8216;", @"'"}, {@"&#8217;", @"'"}, {@"&#8220;", @"'"}, {@"&#8221;", @"\""}, {@"&#038;", @"&"}};
    NSString *retString = inString;
    for (int i=0; i<NUM_VALUES; i++)
    {
        retString = [retString stringByReplacingOccurrencesOfString:values[i].symbol withString:values[i].value];
    }
    
    return retString;
}

- (NSString *) convertDate:(NSString *)initialDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    //    [formatter setDateStyle:NSDateFormatterShortStyle];
    //    [formatter setTimeStyle:NSDateFormatterShortStyle];
    //    [formatter setDateFormat:@"yyyy-MM-dd HH:MM:SS"];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
    
    
    
    //SET YOUT TIMEZONE HERE
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDate *myDate = [formatter dateFromString:initialDate];
    
    [formatter setDateFormat:@"MMM dd"];
    return[formatter stringFromDate:myDate];
    
    /*    NSString *month = [initialDate substringWithRange:NSMakeRange(5, 2)];
     NSString *day = [initialDate substringWithRange:NSMakeRange(8, 2)];
     int monthNum = [month intValue];
     int dayNum = [day intValue];
     
     //    NSString *day = [initialDate substringWithRange:NSMakeRange(5, 2)];
     NSDateFormatter *dateformatter = [[NSDateFormatter alloc]init];
     NSString *extensions[4] = {@"st", @"nd", @"rd", @"th"};
     
     return [NSString stringWithFormat:@"%@ %d%@", [dateformatter standaloneMonthSymbols][monthNum], dayNum, extensions[MIN(dayNum, 3)]];
     */
    /*    [dateformatter setDateStyle:NSDateFormatterShortStyle];
     [dateformatter setTimeStyle:NSDateFormatterNoStyle];
     [dateformatter setDateFormat:@"yyyy-MM-dd"];
     NSDate *myDate = [[NSDate alloc] init];
     
     //SET YOUT TIMEZONE HERE
     dateformatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"PDT"];
     myDate = [dateformatter dateFromString:initialDate];
     [dateformatter standaloneMonthSymbols][]
     myDate.month
     
     return [dateformatter stringFromDate:myDate];
     */
}


- (void) initWithDictionary:(NSDictionary*)post
{
//    CGRect screenBounds = [[UIScreen mainScreen] bounds];
//    CGFloat screenScale = [[UIScreen mainScreen] scale];
//    float width = screenBounds.size.width * screenScale;

    title = [self convertWordPressString:[post objectForKey:@"title"]];
    description = [post objectForKey:@"content"];

    NSRange range = [description rangeOfString:@"width="];
    while(range.location != NSNotFound)
    {
        NSRange rangeTillEnd = NSMakeRange(range.location + 1, [description length] - range.location - 1);
//debug        NSString *testSection = [description substringWithRange:rangeTillEnd];
        NSRange endPos = [description rangeOfString:@"\" " options:0 range:rangeTillEnd];
        NSRange widthRange = NSMakeRange(range.location+7, endPos.location - (range.location+7));
        if ((endPos.location != NSNotFound) && (endPos.location > (range.location+7)))
        {
        description = [description stringByReplacingCharactersInRange:widthRange withString:@"100%%"];
//        int imageWidth = [[description substringWithRange:NSMakeRange(range.location+7, endPos.location - (range.location+7))] intValue];
        }
        
        range = [description rangeOfString:@"width=" options:0 range:NSMakeRange(range.location + 1, [description length] - range.location - 1)];
    }

//    description = [description stringByReplacingOccurrencesOfString:@"width=" withString:@"wad="];
    description = [description stringByReplacingOccurrencesOfString:@"height=" withString:@"hat="];
    NSNumber *objID = [post objectForKey:@"id"];
    postID = objID.intValue;
    NSString *rawDate = [post objectForKey:@"date"];
    dateString = [self convertDate:rawDate];
    //            newPost.requiresDownload = true;
    NSDictionary *authorDict = [post objectForKey:@"author"];
    author = [authorDict objectForKey:@"name"];
    
    postURL = [post objectForKey:@"url"];
    
    NSArray *attachments = [post objectForKey:@"attachments"];
    NSString *fullContent = @"";
    for (NSDictionary *attachment in attachments)
    {
        NSString *mimeType = [attachment objectForKey:@"mime_type"];
        /*                if ([mimeType hasPrefix:@"image"])
         {
         NSDictionary *imageList = [attachment objectForKey:@"images"];
         
         if (imageList)
         {
         NSDictionary *imageMed =[imageList objectForKey:@"medium"];
         newPost.imageURLString = [imageMed objectForKey:@"url"];
         }
         else
         {
         newPost.imageURLString = [attachment objectForKey:@"url"];
         }
         
         //                    const char *ch = [newPost.imageURLString cStringUsingEncoding:NSISOLatin1StringEncoding];
         //                    NSString *yourstring = [[NSString alloc]initWithCString:ch encoding:NSUTF8StringEncoding];
         
         
         NSString *imgHTML = [NSString stringWithFormat:@"<div><a><img src=\"%@\" /></a></div>", newPost.imageURLString];
         fullContent = [fullContent stringByAppendingString:imgHTML];
         
         //                    NSString *fullPost = [NSString stringWithFormat:@"<div><a><img src=\"%@\" /></a></div><div style='text-align:justify; font-size:45px;font-family:HelveticaNeue-CondensedBold;color:#0000;'>%@</div>", newPost.imageURLString, newPost.description];
         //                    NSString *imgBlock = [NSString stringWithFormat:@"<div><a><img width=320 height=240 src=\"%@\" /></a></div>", newPost.imageURLString];
         //                    newPost.description = fullPost;//[imgBlock stringByAppendingString:newPost.description];
         //                    [newPost.description stringByAppendingString:@"<div><a><img width=320 height=240 src=\""];
         
         //            NSString *fullString = [NSString stringWithFormat:@"<div style='text-align:justify; font-size:45px;font-family:HelveticaNeue-CondensedBold;color:#0000;'>%@</div>", [self.detailItem description]];
         
         }
         else */if ([mimeType hasPrefix:@"audio"])
         {
             TrackInfo *trackInfo = [TrackInfo alloc];
             trackInfo->url = [attachment objectForKey:@"url"];
             trackInfo->title = [attachment objectForKey:@"title"];
             trackInfo->duration = 0.0f;
             
             [self addTrack:trackInfo];
         }
    }
    
    NSDictionary *thumbs = [post objectForKey:@"thumbnail_images"];
    NSDictionary *image =[thumbs objectForKey:@"medium"];
//    NSNumber *objWidth = [image objectForKey:@"width"];
//    NSNumber *objHeight = [image objectForKey:@"height"];
    imageURLString = [image objectForKey:@"url"];
//    float scale = 1.0f;///(width / objWidth.floatValue);
    NSString *imgHTML = [NSString stringWithFormat:@"<div><a><img src=\"%@\" width='100%%'/></a></div>", imageURLString];
//    NSString *imgHTML = [NSString stringWithFormat:@"<div><a><img src=\"%@\" width=\"%d\" height=\"%d\"/></a></div>", imageURLString, (int)(objWidth.intValue*scale), (int)(objHeight.intValue*scale)];
    fullContent = [fullContent stringByAppendingString:imgHTML];
    
    NSString *blurbFormat = @"<meta name='viewport' content='width=device-width; initial-scale=1, maximum-scale=1'><div style='text-align:justify; font-size:12px;font-family:HelveticaNeue-CondensedBold;color:#0000;'>%@</div>";
    blurb = [NSString stringWithFormat:blurbFormat, description];
    
    NSString *postFormat = @"<meta name='viewport' content='width=device-width; initial-scale=1, maximum-scale=1'>\
    <div style='font-size:15px;font-family:HelveticaNeue-CondensedBold;color:#0000;'><h1>%@</h1></div>\
    <p><div style='font-size:8px;float:left'>%@</div> <div style='font-size:8px;float:right'>%@</div></p><br/>\
    %@\
    <div style='text-align:justify; font-size:14px;font-family:HelveticaNeue-CondensedBold;color:#0000;'>%@</div>";
//    NSString *postFormat = @"<meta name='viewport' content='width=device-width; initial-scale=1, maximum-scale=1'>\
//    <div style='font-size:45px;font-family:HelveticaNeue-CondensedBold;color:#0000;'><h1>%@</h1></div>\
//    <p><div style='font-size:30px;float:left'>%@</div> <div style='font-size:30px;float:right'>%@</div></p><br/>\
//    %@\
//    <div style='text-align:justify; font-size:30px;font-family:HelveticaNeue-CondensedBold;color:#0000;'>%@</div>";
    description = [NSString stringWithFormat:postFormat, title, author, dateString, fullContent, description];
    
    [self setup];
}

- (void) setup
{
    imageURLString = [self findProperty:@"img"];
    
    NSString *media = [self findProperty:@"iframe"];

//    static int LAST_ID = 0;
//    LAST_ID++;
    
    _type = Text;
//    postID = LAST_ID;
    
    if (tracks)
    {
        _type = Audio;
    }

    if (media)
    {
//        https://api.soundcloud.com/tracks/3100297/stream?client_id=YOUR_CLIENT_ID
        NSRange rangeOuter = [media rangeOfString:@"soundcloud"];
        if (rangeOuter.location != NSNotFound)
        {
            NSRange rangeToSearchWithin = NSMakeRange(rangeOuter.location, media.length - rangeOuter.location);
            NSRange range = [media rangeOfString:@"url" options:0 range:rangeToSearchWithin];
            if (range.location != NSNotFound)
            {
                NSRange rangeToSearchWithin2 = NSMakeRange(range.location, media.length - range.location);
                NSRange range2 = [media rangeOfString:@"&" options:0 range:rangeToSearchWithin2];
                NSRange urlRange;
                if (range2.location == NSNotFound)
                {
                    urlRange = NSMakeRange(range.location+4, [media length]-(range.location+4));
                }
                else
                {
                    urlRange = NSMakeRange(range.location+4, range2.location-(range.location+4));
                }
                mediaURLString = [media substringWithRange:urlRange];
//                mediaURLString = [media substringFromIndex:range.location+4];
                mediaURLString = [mediaURLString stringByReplacingOccurrencesOfString:@"%3A" withString:@":"];
                mediaURLString = [mediaURLString stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
                mediaURLString = [mediaURLString stringByAppendingString:@"/stream?client_id=YOUR_CLIENT_ID"];
                
                TrackInfo *newTrack = [TrackInfo alloc];
                newTrack->title = self.title;
                newTrack->url = mediaURLString;
                [self addTrack:newTrack];
                
                _type = Audio;
            }
        }
        else if ([media rangeOfString:@"bandcamp"].location != NSNotFound)
        {
            NSRange range = [media rangeOfString:@"track="];
            if (range.location != NSNotFound)
            {
                NSRange rangeToSearchWithin = NSMakeRange(range.location, media.length - range.location);
                NSRange rangeEnd = [media rangeOfString:@"/" options:0 range:rangeToSearchWithin];

                if ((range.location != NSNotFound)
                    && (rangeEnd.location != NSNotFound))
                {
                    range.location += 6;
                    range.length = media.length - rangeEnd.location;
                    mediaURLString = [NSString stringWithFormat:BAND_CAMP_TRACK_URL, [media substringWithRange:range]];
                
                    TrackInfo *newTrack = [TrackInfo alloc];
                    newTrack->title = self.title;
                    newTrack->url = mediaURLString;
                    [self addTrack:newTrack];

                    _type = Audio;
                }
            }
            else
            {
                NSRange albumRange = [media rangeOfString:@"album="];
                if (albumRange.location != NSNotFound)
                {
                    NSRange rangeToSearchWithin = NSMakeRange(albumRange.location, media.length - albumRange.location);
                    NSRange rangeEnd = [media rangeOfString:@"/" options:0 range:rangeToSearchWithin];

                    if (rangeEnd.location != NSNotFound)
                    {
                        albumRange.location += 6;
                        albumRange.length = rangeEnd.location-albumRange.location;
                        NSString *url = [BAND_CAMP_ALBUM_QUERY stringByAppendingString:[media substringWithRange:albumRange]];
                        
                        m_receivedDataTracks = [[NSMutableData alloc] init];

                        //Create the connection with the string URL and kick it off
                        m_tracksQuery = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
                        [m_tracksQuery start];
                    }
                }
            }
        }
        else if ([media rangeOfString:@"youtube"].location != NSNotFound)
        {
            _type = Video;
        }
    }

/*            //    			https://api.soundcloud.com/tracks/3100297/stream?client_id=YOUR_CLIENT_ID
            _mediaSource = theWebView.replace("http://w.soundcloud.com/player/?url=", "");
            _mediaSource = theWebView.replace("https://w.soundcloud.com/player/?url=", "");
            _mediaSource = _mediaSource.replace("%3A", ":");
            _mediaSource = _mediaSource.replace("%2F", "/");
            
            //    			int trackidx = _mediaSource.indexOf("tracks/");
            //    			if (trackidx >= 0)
            //    			{
            //					_mediaSource = _mediaSource.substring(trackidx+7);
            //    			}
            
            Integer cut = _mediaSource.indexOf('&');
            if (cut >= 0)
            {
                _mediaSource = _mediaSource.substring(0, cut);
            }
            _mediaSource = _mediaSource + "/stream?client_id=YOUR_CLIENT_ID";
            
            _mediaType = EMediaType.Media_Audio;
 */
 /*       else if (theWebView.contains("bandcamp"))
        {
            int trackidx = theWebView.indexOf("track=");
            int endpt = theWebView.indexOf("/", trackidx);
            if ((trackidx >= 0) && (endpt >= 0))
            {
                String trackNumber = theWebView.substring(trackidx+6, endpt);
                _mediaSource = String.format("http://popplers5.bandcamp.com/download/track?enc=mp3-128&id=%s&stream=1", trackNumber);
                _mediaType = EMediaType.Media_Audio;
            }
            / *    			else
             {
             int albumidx = theWebView.indexOf("album=");
             endpt = theWebView.indexOf("/", albumidx);
             if ((albumidx >= 0) && (endpt >= 0))
             {
             String albumNumber = theWebView.substring(albumidx+6, endpt);
             _mediaSource = String.format("http://popplers5.bandcamp.com/download/album?enc=mp3-128&id=%s&stream=1", albumNumber);
             _mediaType = EMediaType.Media_Audio;
             }
             }
             * /    		}   
    }*/
}

- (void)addTrack:(TrackInfo *) track
{
    if (tracks == NULL)
    {
        tracks = [[NSMutableArray alloc] init];
    }
    
    [tracks addObject:track];
}


- (UIImage *) requestImage:(id<IconDownloaderDelegate>)delegate;
{
    if ((appIcon == NULL) && (imageURLString != NULL))
    {
        [IconDownloader download:self delegate:delegate];
    }

    return appIcon;
}

- (void) requestFullFeed:(id<PostRequestDelegate>)delegate
{
    NSString *url = [@"http://www.thewordisbond.com/?json=get_post&id=" stringByAppendingFormat:@"%d", postID];
    
    m_delegate = delegate;
    m_receivedData = [[NSMutableData alloc] init];
    requiresDownload = false;
    
    //Create the connection with the string URL and kick it off
    NSURLConnection *urlConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
    [urlConnection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection == m_tracksQuery)
    {
        [m_receivedDataTracks setLength:0];
    }
    else
    {
        //Reset the data as this could be fired if a redirect or other response occurs
        [m_receivedData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == m_tracksQuery)
    {
        [m_receivedDataTracks appendData:data];
    }
    else
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
    if (connection == m_tracksQuery)
    {
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:m_receivedDataTracks
                              options:kNilOptions
                              error:NULL];
        
        NSArray *tracksArray = [json objectForKey:@"tracks"];
        for (NSDictionary *track in tracksArray)
        {
            TrackInfo *newTrack = [TrackInfo alloc];
            newTrack->title = [track objectForKey:@"title"];
            newTrack->url = [NSString stringWithFormat:BAND_CAMP_TRACK_URL, ((NSNumber*)([track objectForKey:@"track_id"])).stringValue];
//            newTrack->url = [track objectForKey:@"streaming_url"];
            newTrack->duration = ((NSNumber*)([track objectForKey:@"duration"])).floatValue;
            [self addTrack:newTrack];
        }
        _type = Audio;
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"NewTrackInfo"
         object:self];
    }
    else
    {
    //Start the XML parser with the delegate pointing at the current object
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:m_receivedData
                          options:kNilOptions
                          error:NULL];
    
    NSDictionary* post = [json objectForKey:@"post"];
    if (post)
    {
        [self initWithDictionary:post];
/*        NSString *postContent = [post objectForKey:@"content"];
        if (postContent)
        {
            description = postContent;
            
            NSString *imgBlock = [NSString stringWithFormat:@"<div><a><img src=\"%@\" /></a></div>", imageURLString];
            description = [imgBlock stringByAppendingString:description];

            [self setup];
        
            [m_delegate fullPostDidLoad:self];
        }*/

        [m_delegate fullPostDidLoad:self];
    }
    requiresDownload = false;
    }
}

- (void) updateImage:(UIImage *)image
{
    appIcon = image;
    blurredImage = [image applyLightEffect];
}


@end
