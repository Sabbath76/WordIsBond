//
//  CRSSItem.m
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "CRSSItem.h"

@implementation CRSSItem
{
    NSMutableData *m_receivedData;
    id<PostRequestDelegate> m_delegate;
}

@synthesize title, description, imageURLString, appIcon, mediaURLString, postID, requiresDownload;

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

- (void) setup
{
    imageURLString = [self findProperty:@"img"];
    
    NSString *media = [self findProperty:@"iframe"];

//    static int LAST_ID = 0;
//    LAST_ID++;
    
    _type = Text;
//    postID = LAST_ID;

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
                mediaURLString = [media substringFromIndex:range.location+4];
                mediaURLString = [mediaURLString stringByReplacingOccurrencesOfString:@"%3A" withString:@":"];
                mediaURLString = [mediaURLString stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
                mediaURLString = [mediaURLString stringByAppendingString:@"/stream?client_id=YOUR_CLIENT_ID"];
                
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
                    range.length =media.length - rangeEnd.location;
                    mediaURLString = [NSString stringWithFormat:@"http://popplers5.bandcamp.com/download/track?enc=mp3-128&id=%@&stream=1", [media substringWithRange:range]];
                
                    _type = Audio;
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

- (UIImage *) requestImage:(id<IconDownloaderDelegate>)delegate;
{
    if (appIcon == NULL)
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
    
    //Create the connection with the string URL and kick it off
    NSURLConnection *urlConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
    [urlConnection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //Reset the data as this could be fired if a redirect or other response occurs
    [m_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Append the received data each time this is called
    [m_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //Start the XML parser with the delegate pointing at the current object
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:m_receivedData
                          options:kNilOptions
                          error:NULL];
    
    NSDictionary* post = [json objectForKey:@"post"];
    if (post)
    {
        NSString *postContent = [post objectForKey:@"content"];
        if (postContent)
        {
            description = postContent;
            
            NSString *imgBlock = [NSString stringWithFormat:@"<div><a><img src=\"%@\" /></a></div>", imageURLString];
            description = [imgBlock stringByAppendingString:description];

            [self setup];
        
            [m_delegate fullPostDidLoad:self];
        }
    }
    requiresDownload = false;
}

@end
