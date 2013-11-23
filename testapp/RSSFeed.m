//
//  RSSFeed.m
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//


#import "CRSSItem.h"
#import "RSSFeed.h"

@implementation RSSFeed
{
    NSMutableArray *sourceItems;
    NSMutableArray *sourceFeatures;
    NSMutableData *m_receivedData;
    int m_page;
    int m_totalPages;
    NSString *m_lastSearch;
    Boolean m_insertFront;
}

@synthesize items, features, numNewBack, numNewFront, reset;

- (void)handleLoadedApps:(NSArray *)loadedApps
{
    //    [self.appRecords addObjectsFromArray:loadedApps];
    
    sourceItems = [[NSMutableArray alloc] init];
    sourceFeatures = [[NSMutableArray alloc] init];
    items = [[NSMutableArray alloc] init];
    features = [[NSMutableArray alloc] init];
    for (CRSSItem *item in loadedApps)
    {
        [items insertObject:item atIndex:0];
        [features insertObject:item atIndex:0];
        [sourceItems insertObject:item atIndex:0];
        [sourceFeatures insertObject:item atIndex:0];
    }
}

+ (RSSFeed *) getInstance
{
    static RSSFeed *s_RSSFeed = NULL;
    if (s_RSSFeed == NULL)
    {
        s_RSSFeed = [RSSFeed alloc];
        s_RSSFeed->m_page = 0;
        s_RSSFeed->m_totalPages = 0;
    }
    
    return s_RSSFeed;
}

- (void) Filter:(NSString *)filter showAudio:(bool)showAudio showVideo:(bool)showVideo showText:(bool)showText
{
    if (sourceItems == nil)
    {
        [self LoadFeed];
    }
    else
    {
        [items removeAllObjects];
        [features removeAllObjects];
        for (CRSSItem *item in sourceItems)
        {
            if (!showAudio && (item.type == Audio))
                continue;
            if (!showVideo && (item.type == Video))
                continue;
            if (!showText && (item.type == Text))
                continue;
            if (filter && ([item.title rangeOfString:filter].location == NSNotFound))
                continue;
            
            [items insertObject:item atIndex:0];
        }
        for (CRSSItem *item in sourceFeatures)
        {
            if (!showAudio && (item.type == Audio))
                continue;
            if (!showVideo && (item.type == Video))
                continue;
            if (!showText && (item.type == Text))
                continue;
            if (filter && ([item.title rangeOfString:filter].location == NSNotFound))
                continue;
            
            [features insertObject:item atIndex:0];
        }
    }
}

- (void) QueryAPI:(NSString *)url reset:(Boolean)doReset
{
    m_receivedData = [[NSMutableData alloc] init];
    reset = doReset;
    
    //Create the connection with the string URL and kick it off
    NSURLConnection *urlConnection = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
    [urlConnection start];
//    NSURLConnection
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
    [[NSNotificationCenter defaultCenter]
         postNotificationName:@"FailedFeed"
         object:self];
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

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //Start the XML parser with the delegate pointing at the current object
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:m_receivedData
                          options:kNilOptions
                          error:NULL];
    
    NSNumber *numItems = [json objectForKey:@"count"];
    if (numItems.intValue > 0)
    {
        if (reset)
        {
            items = [[NSMutableArray alloc] init];
            features = [[NSMutableArray alloc] init];
        }

        NSNumber *pages = [json objectForKey:@"pages"];
        m_totalPages = pages.intValue;

        numNewFront = 0;
        numNewBack = 0;
    
        NSArray *posts = [json objectForKey:@"posts"];
        for (NSDictionary *post in posts)
        {
            NSNumber *postIdx = [post objectForKey:@"id"];
            bool skip = false;
            
            if (reset == false)
            {
                //--- Check for inserting new posts
                for (CRSSItem *oldPost in items)
                {
                    if (oldPost.postID == postIdx.integerValue)
                    {
                        //--- Terminate
                        skip = true;
                        break;
                    }
                }
            }
            
            if (!skip)
            {
                CRSSItem *newPost = [CRSSItem alloc];
                [newPost initWithDictionary:post];
            
                if (m_insertFront)
                {
                    [items insertObject:newPost atIndex:numNewFront];
                    [features insertObject:newPost atIndex:numNewFront];
                    numNewFront++;
                }
                else
                {
                    [items addObject:newPost];
                    [features addObject:newPost];
                    numNewBack++;
                }
            }
        }
        
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"NewRSSFeed"
         object:self];
    }
    else
    {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"FailedFeed"
         object:self];
    }
}

- (void) LoadFeed
{
    NSString *url = @"http://www.thewordisbond.com/?json=appqueries.get_recent_posts&count=20";
    m_lastSearch = url;
    m_insertFront = false;
    [self QueryAPI:url reset:true];
    m_page = 0;
}

- (void) FilterJSON:(NSString *)filter showAudio:(bool)showAudio showVideo:(bool)showVideo showText:(bool)showText
{
    NSString *url = [@"http://www.thewordisbond.com/?json=appqueries.get_search_results&count=20&search=" stringByAppendingString:filter];
    m_lastSearch = url;
    m_insertFront = false;
    [self QueryAPI:url reset:true];
    m_page = 0;
}

- (int) GetPage
{
    return m_page;
}
- (int) GetNumPages
{
    return m_totalPages;
}


- (void) LoadPage:(int) pageNum
{
    NSString *url = [m_lastSearch stringByAppendingFormat:@"&page=%d",pageNum+1];
    [self QueryAPI:url reset:false];
    m_insertFront = pageNum <= m_page;
    m_page = pageNum;
}


@end
