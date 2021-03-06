//
//  CRSSItem.m
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "CRSSItem.h"
#import "UIImage+ImageEffects.h"
#import "AVFoundation/AVUtilities.h"
#import "CoreDefines.h"

@implementation CRSSItem
{
    bool isFeature;
    
    id<PostRequestDelegate> m_delegate;
    
    NSURLConnection *m_fullPostQuery;
    NSMutableData *m_receivedData;
    NSURLConnection *m_tracksQuery;
    NSMutableData *m_receivedDataTracks;
    
    UIImage *m_listImage;
    
//    AudioHost m_audioHost;
}

static UIImage *defaultIcon;
static UIImage *defaultImage;
static UIImage *defaultBlurredImage;

//static NSString * BAND_CAMP_KEY = @"godsthannlitanpalafreyregna";
//static NSString * BAND_CAMP_ALBUM_QUERY = @"http://api.bandcamp.com/api/album/2/info?key=godsthannlitanpalafreyregna&album_id=";
//static NSString * BAND_CAMP_TRACK_URL = @"http://popplers5.bandcamp.com/download/track?enc=mp3-128&id=%@&stream=1";

@synthesize title, imageURLString, appIcon, iconImage, mediaURLString, postID, audioHost, requiresDownload, tracks, dateString, author, blurb, postURL, blurredImage;

- (NSString*) findProperty:(NSString *)search desc:(NSString *)description
{
    NSRange rangeOuter = [description rangeOfString:search];
    if (rangeOuter.location != NSNotFound)
    {
        NSRange rangeToSearchWithin = NSMakeRange(rangeOuter.location, description.length - rangeOuter.location);
        NSRange range = [description rangeOfString:@"src" options:0 range:rangeToSearchWithin];
        if (range.location != NSNotFound)
        {
            NSInteger startPos = range.location+range.length;
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

+ (void) setupDefaults
{
    if (defaultImage == nil)
    {
        defaultImage = [UIImage imageNamed:@"user_avatar"];
        defaultBlurredImage = [defaultImage applyLightEffect];
        defaultIcon = [self resizeImage:defaultImage newSize:CGSizeMake(60.0f, 60.0f)];
        
    }
}

+ (void) clearDefaults
{
    defaultImage = nil;
    defaultBlurredImage = nil;
    defaultIcon = nil;
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

static NSDateFormatter *sDateFormatterFrom = nil;
static NSDateFormatter *sDateFormatterTo = nil;
- (NSString *) convertDate:(NSString *)initialDate
{
    if (sDateFormatterFrom == nil)
    {
        sDateFormatterFrom = [[NSDateFormatter alloc] init];
        [sDateFormatterFrom setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
        sDateFormatterFrom.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    }
    if (sDateFormatterTo == nil)
    {
        sDateFormatterTo = [[NSDateFormatter alloc] init];
        [sDateFormatterTo setDateFormat:@"MMM dd"];
    }

    NSDate *myDate = [sDateFormatterFrom dateFromString:initialDate];
    return[sDateFormatterTo stringFromDate:myDate];
}

- (void) initAsStub:(int)postId postTitle:(NSString*)postTitle isFeature:(bool)_isFeature
{
    title = postTitle;
    postID = postId;
    isFeature = _isFeature;
    requiresDownload = true;
}

- (void) initWithDictionary:(NSDictionary*)post isFeature:(bool)_isFeature
{
//    CGRect screenBounds = [[UIScreen mainScreen] bounds];
//    CGFloat screenScale = [[UIScreen mainScreen] scale];
//    float width = screenBounds.size.width * screenScale;

    title = [self convertWordPressString:[post objectForKey:@"title_plain"]];
    NSString *description = [post objectForKey:@"content"];
    isFeature = _isFeature;

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
    _type = Text;

    NSArray *attachments = [post objectForKey:@"attachments"];
//    NSString *fullContent = @"";
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
             _type = Audio;
             
             TrackInfo *trackInfo = [TrackInfo alloc];
             trackInfo->url = [attachment objectForKey:@"url"];
             trackInfo->title = [attachment objectForKey:@"title"];
             trackInfo->duration = 0.0f;
             
             [self addTrack:trackInfo];
         }
    }
    
    NSDictionary *customData = [post objectForKey:@"custom_fields"];
    if (customData)
    {
        NSArray *pMediaUrl = [customData objectForKey:@"vw_post_format_audio_oembed_url"];
        if (!pMediaUrl)
        {
            pMediaUrl = [customData objectForKey:@"vw_post_format_audio_oembed_code"];
        }
        
        if (pMediaUrl)
        {
            NSString *pMediaUrlString = pMediaUrl[0];
            [self setMediaURL:pMediaUrlString];
        }
    }
    
    if (_type == Text)
    {
        //--- Not found anything else? Fallback to the iFrame
        NSString *media = [self findProperty:@"iframe" desc:description];
        if (media)
        {
            [self setMediaURL:media];
        }
    }
    
    NSDictionary *thumbs = [post objectForKey:@"thumbnail_images"];
    NSDictionary *image;
    if (isFeature)
    {
        image =[thumbs objectForKey:@"large"];
    }
    else
    {
        image =[thumbs objectForKey:@"medium"];
    }
//    NSNumber *objWidth = [image objectForKey:@"width"];
//    NSNumber *objHeight = [image objectForKey:@"height"];
    imageURLString = [image objectForKey:@"url"];
//    float scale = 1.0f;///(width / objWidth.floatValue);
/*    NSString *imgHTML = [NSString stringWithFormat:@"<div><a><img src=\"%@\" width='100%%'/></a></div>", imageURLString];
//    NSString *imgHTML = [NSString stringWithFormat:@"<div><a><img src=\"%@\" width=\"%d\" height=\"%d\"/></a></div>", imageURLString, (int)(objWidth.intValue*scale), (int)(objHeight.intValue*scale)];
    fullContent = [fullContent stringByAppendingString:imgHTML];
*/
//    NSString *blurbFormat = @"<head><style>a:link {color:#844434;text-decoration:underline;}</style></head><meta name='viewport' content='width=device-width; initial-scale=1, maximum-scale=1'><div style='text-align:justify; font-size:16px;font-family:HelveticaNeue;color:#FFFF;'>%@</div>";
    NSString *blurbFormat = @"<head><style>a:link {color:#844434;text-decoration:underline;}</style></head><meta name='viewport' content='width=device-width; initial-scale=1, maximum-scale=1'><div style='text-align:justify; font-size:16px;font-family:MyriadPro-Regular;color:#FFFF;'>%@</div>";

    blurb = [NSString stringWithFormat:blurbFormat, description];
    
/*    NSString *disqusCommentBlock = @"<a name=\"comments\"/> <div id=\"disqus_thread\"></div>\
    <script type=\"text/javascript\">\
    var disqus_shortname = 'wordisbond';\
    (function() {\
        var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;\
        dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';\
        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);\
    })();\
    </script>\
    <noscript>Please enable JavaScript to view the <a href=\"http://disqus.com/?ref_noscript\">comments powered by Disqus.</a></noscript>\
    <a href=\"http://disqus.com\" class=\"dsq-brlink\">blog comments powered by <span class=\"logo-disqus\">Disqus</span></a>";
 
    blurb = [blurb stringByAppendingString:disqusCommentBlock];*/

    [self setup];
}

- (void) setMediaURL:(NSString *)media
{
    NSRange rangeOuter = [media rangeOfString:@"soundcloud"];
    if (rangeOuter.location != NSNotFound)
    {
        _type = Audio;
        audioHost = Soundcloud;
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
            mediaURLString = [mediaURLString stringByReplacingOccurrencesOfString:@"%3A" withString:@":"];
            mediaURLString = [mediaURLString stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
            mediaURLString = [mediaURLString stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            if ([mediaURLString containsString:@"playlist"])
            {
                mediaURLString = [mediaURLString stringByAppendingString:@".json?client_id=YOUR_CLIENT_ID"];
                m_receivedDataTracks = [[NSMutableData alloc] init];
                m_tracksQuery = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:mediaURLString]] delegate:self];
                [m_tracksQuery start];
            }
            else if ([mediaURLString containsString:@"track"])
            {
                mediaURLString = [mediaURLString stringByAppendingString:@"/stream?client_id=YOUR_CLIENT_ID"];
                
                TrackInfo *newTrack = [TrackInfo alloc];
                newTrack->title = self.title;
                newTrack->url = mediaURLString;
                newTrack->duration = 0.0f;
                [self addTrack:newTrack];
                
            }
        }
            else
            {
                mediaURLString = [NSString stringWithFormat:@"http://api.soundcloud.com/resolve.json?url=%@/tracks&client_id=YOUR_CLIENT_ID", media];
                m_receivedDataTracks = [[NSMutableData alloc] init];
                m_tracksQuery = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:mediaURLString]] delegate:self];
                [m_tracksQuery start];
//                [@"http://api.soundcloud.com/resolve.json?url=" stringByAppendingFormat:@"%@/tracks" media];
//                permalink_url+'/tracks&client_id='+client_id
            }
    }
    else if ([media rangeOfString:@"bandcamp"].location != NSNotFound)
    {
        _type = Audio;
        audioHost = Bandcamp;
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
                newTrack->duration = 0.0f;
                [self addTrack:newTrack];
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

- (void) setup
{
//    imageURLString = [self findProperty:@"img"];
    
    
//    NSString *media = [self findProperty:@"iframe"];
    
//    if (media)
//    {
//        [self setMediaURL:media];
//        https://api.soundcloud.com/tracks/3100297/stream?client_id=YOUR_CLIENT_ID
//    }

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
    
    track->pItem = self;
    [tracks addObject:track];
}

+ (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)coordSize
{
    GLfloat scale = [UIScreen mainScreen].scale;
    
    //    CGSize newSize = CGSizeMake(coordSize.width * scale, coordSize.height * scale);
    CGSize newSize = CGSizeMake(coordSize.width, coordSize.height);
    
    //    GLfloat srcSize = Min(image.size.height, image.size.width);
    //    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, srcSize, srcSize));
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
    if (image.size.width >= image.size.height)
    {
        float aspect = image.size.width / image.size.height;
        newRect.size.width *= aspect;
        newRect.origin.x -= (newRect.size.width - newSize.width) * 0.5f;
    }
    else
    {
        float aspect = image.size.height / image.size.width;
        newRect.size.height *= aspect;
        newRect.origin.y -= (newRect.size.height - newSize.height) * 0.5f;
    }
    // calculate resize ratio, and apply to rect
    //    newRect = AVMakeRectWithAspectRatioInsideRect(image.size, newRect);
    
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:scale orientation:UIImageOrientationUp];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void) updateImage:(UIImage *)image icon:(UIImage *)imgIcon blur:(UIImage *)imgBlur
{
    appIcon = image;
    iconImage = imgIcon;
    blurredImage = imgBlur;
    
//    iconImage = [CRSSItem resizeImage:image newSize:CGSizeMake(60.0f, 60.0f)];
    
//    blurredImage = [iconImage applyLightEffect];
}

- (void) freeImages
{
    appIcon = NULL;
    iconImage = NULL;
    blurredImage = NULL;
}

- (UIImage *) requestImage:(id<IconDownloaderDelegate>)delegate;
{
    if ((appIcon == NULL) && (imageURLString != NULL))
    {
        [IconDownloader download:self delegate:delegate];
    }

    return (appIcon == nil) ? defaultImage : appIcon;
}

- (UIImage *) requestIcon:(id<IconDownloaderDelegate>)delegate;
{
    if ((iconImage == NULL) && (imageURLString != NULL))
    {
        [IconDownloader download:self delegate:delegate];
    }
    
    return (iconImage == nil) ? defaultIcon : iconImage;
}

- (UIImage *) getBlurredImage
{
    return (blurredImage == nil) ? defaultBlurredImage : blurredImage;
}


- (void) requestFullFeed:(id<PostRequestDelegate>)delegate
{
    NSString *url = [SERVER_REQUEST_FULL_POST_URL stringByAppendingFormat:@"%d", postID];
    
    m_delegate = delegate;
    m_receivedData = [[NSMutableData alloc] init];
    requiresDownload = false;
    
    NSURLRequest *pRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
    //Create the connection with the string URL and kick it off
    NSURLConnection *urlConnection = [NSURLConnection connectionWithRequest:pRequest delegate:self];
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
    if (connection == m_tracksQuery)
    {
        m_tracksQuery = nil;
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"NewTrackInfo"
         object:self];
    }
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
        NSString *artist = [json objectForKey:@"artist"];
        if (artist == nil)
        {
            artist = [json objectForKey:@"title"];
        }
        if (tracksArray)
        {
            NSString *albumUrl = [json objectForKey:@"url"];
            NSRange range = [albumUrl rangeOfString:@"/album"];
            NSString *cutUrl = [albumUrl substringToIndex:range.location];
            for (NSDictionary *track in tracksArray)
            {
                TrackInfo *newTrack = [TrackInfo alloc];
                
                if (audioHost == Bandcamp)
                {
                    NSString *trackArtist = [track objectForKey:@"artist"];
                    newTrack->title = [track objectForKey:@"title"];
                    newTrack->url = [NSString stringWithFormat:BAND_CAMP_TRACK_URL, ((NSNumber*)([track objectForKey:@"track_id"])).stringValue];
                    newTrack->sourceUrl = [cutUrl stringByAppendingString:[track objectForKey:@"url"]];
        //            newTrack->url = [track objectForKey:@"streaming_url"];
                    newTrack->duration = ((NSNumber*)([track objectForKey:@"duration"])).floatValue;
                    newTrack->artist = (trackArtist != nil) ? trackArtist : artist;
                }
                else if (audioHost == Soundcloud)
                {
                    newTrack->title = [track objectForKey:@"title"];
                    newTrack->url = [track objectForKey:@"stream_url"];
                    newTrack->url = [newTrack->url stringByAppendingString:@"?client_id=YOUR_CLIENT_ID"];
                    if ([track objectForKey:@"purchase_url"] != [NSNull null])
                    {
                        newTrack->sourceUrl = [track objectForKey:@"purchase_url"];
                    }
                    else
                    {
                        newTrack->sourceUrl = [track objectForKey:@"permalink_url"];
                    }
                    newTrack->duration = ((NSNumber*)([track objectForKey:@"duration"])).floatValue/1000.0f;
                    newTrack->artist = artist;
                }
                [self addTrack:newTrack];
            }
        }
        else
        {
            NSString *streamUrl = [json objectForKey:@"stream_url"];
            
            if (streamUrl)
            {
                TrackInfo *newTrack = [TrackInfo alloc];
                newTrack->title = [json objectForKey:@"title"];
                if ([streamUrl containsString:@"?"])
                {
                    newTrack->url = [streamUrl stringByAppendingString:@"&"];
                }
                else
                {
                    newTrack->url = [streamUrl stringByAppendingString:@"?"];
                }
                newTrack->url = [newTrack->url stringByAppendingString:@"client_id=YOUR_CLIENT_ID"];
                if ([json objectForKey:@"purchase_url"] != [NSNull null])
                {
                    newTrack->sourceUrl = [json objectForKey:@"purchase_url"];
                }
                else
                {
                    newTrack->sourceUrl = [json objectForKey:@"permalink_url"];
                }
                newTrack->duration = ((NSNumber*)([json objectForKey:@"duration"])).floatValue/1000.0f;
                newTrack->artist = artist;
                [self addTrack:newTrack];
            }
        }
        _type = Audio;
        
        m_tracksQuery = nil;
        
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
        [self initWithDictionary:post isFeature:isFeature];
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
    
    m_receivedData = nil;
}

- (Boolean) waitingOnTracks;
{
    if (m_tracksQuery != nil)
    {
        return true;
    }
    
    return false;
}

@end
