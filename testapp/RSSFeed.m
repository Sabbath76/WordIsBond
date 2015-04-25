//
//  RSSFeed.m
//  testapp
//
//  Created by Jose Lopes on 21/04/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//


#import "CRSSItem.h"
#import "RSSFeed.h"
#import "CoreDefines.h"

@implementation RSSFeed
{
    NSMutableArray *m_mainItems;
    NSMutableArray *m_mainFeatures;
    NSMutableArray *m_searchItems;
    NSMutableArray *m_searchFeatures;
    NSMutableArray *m_filteredItems;
    NSMutableArray *m_filteredFeatures;

    int m_mainPage;
    int m_mainTotalPages;
    int m_searchPage;
    int m_searchTotalPages;

    NSMutableData *m_receivedData;
    NSMutableData *m_receivedDataFeatures;
    NSURLConnection *m_connectionPosts;
    NSURLConnection *m_connectionFeatures;
    NSString *m_lastURLPosts;
    NSString *m_lastURLFeatures;
//    int m_page;
//    int m_totalPages;
    NSString *m_lastSearch;
    Boolean m_insertFront;
    bool m_resetFeatures;
    bool m_hasSearch;
    
    bool m_showAudio;
    bool m_showVideo;
    bool m_showText;
}

@synthesize /*items, features,*/ numNewBack, numNewFront, reset;

//static NSString *SERVER_POSTS_URL = @"http://www.thewordisbond.com/?json=appqueries.get_recent_posts&count=20";
//static NSString *SERVER_FEATURES_URL = @"http://www.thewordisbond.com/?json=appqueries.get_recent_features&count=5";
//static NSString *SERVER_SEARCH_POSTS_URL = @"http://www.thewordisbond.com/?json=appqueries.get_search_results&count=20&search=";
//static NSString *SERVER_SEARCH_FEATURES_URL = @"http://www.thewordisbond.com/?json=appqueries.get_search_feature_results&count=5&search=";

/*- (void)handleLoadedApps:(NSArray *)loadedApps
{
    //    [self.appRecords addObjectsFromArray:loadedApps];
    
    m_sourceItems = [[NSMutableArray alloc] init];
    m_sourceFeatures = [[NSMutableArray alloc] init];
    items = [[NSMutableArray alloc] init];
    features = [[NSMutableArray alloc] init];
    for (CRSSItem *item in loadedApps)
    {
        [items insertObject:item atIndex:0];
        [features insertObject:item atIndex:0];
        [m_sourceItems insertObject:item atIndex:0];
        [m_sourceFeatures insertObject:item atIndex:0];
    }
}*/

+ (RSSFeed *) getInstance
{
    static RSSFeed *s_RSSFeed = NULL;
    if (s_RSSFeed == NULL)
    {
        s_RSSFeed = [[RSSFeed alloc] init];
    }
    
    return s_RSSFeed;
}

- (id) init
{
    self = [super init];
    
    m_mainPage = 0;
    m_mainTotalPages = 0;
    m_searchPage = 0;
    m_searchTotalPages = 0;
    
    m_resetFeatures = false;
    m_hasSearch = false;
    
    m_showAudio = true;
    m_showVideo = true;
    m_showText  = true;
    
    m_mainItems = [[NSMutableArray alloc] init];
    m_mainFeatures = [[NSMutableArray alloc] init];
    m_searchItems = [[NSMutableArray alloc] init];
    m_searchFeatures = [[NSMutableArray alloc] init];
    m_filteredItems = [[NSMutableArray alloc] init];
    m_filteredFeatures = [[NSMutableArray alloc] init];
    
    return self;
}

- (void) UpdateFilteredItems
{
    NSMutableArray *pItems     = m_hasSearch ? m_searchItems : m_mainItems;
    NSMutableArray *pFeatures  = m_hasSearch ? m_searchFeatures : m_mainFeatures;
    
    [m_filteredItems removeAllObjects];
    [m_filteredFeatures removeAllObjects];
    for (CRSSItem *item in pItems)
    {
        if (!m_showAudio && (item.type == Audio))
            continue;
        if (!m_showVideo && (item.type == Video))
            continue;
        if (!m_showText && (item.type == Text))
            continue;
        
        [m_filteredItems addObject:item];
    }
    for (CRSSItem *item in pFeatures)
    {
        if (!m_showAudio && (item.type == Audio))
            continue;
        if (!m_showVideo && (item.type == Video))
            continue;
        if (!m_showText && (item.type == Text))
            continue;
        
        [m_filteredFeatures addObject:item];
    }
  
    //--- Inform the rest of the app about the new data
//    reset = true;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"NewRSSFeed"
     object:self];
    reset = false;
}

- (void) showAudio:(bool)showAudio showVideo:(bool)showVideo showText:(bool)showText
{
    m_showAudio = showAudio;
    m_showVideo = showVideo;
    m_showText  = showText;
    
    reset = true;
    
    [self UpdateFilteredItems];
}

- (void) QueryAPI:(NSString *)url reset:(Boolean)doReset
{
    m_receivedData = [[NSMutableData alloc] init];
    reset = doReset;
    m_lastURLPosts = url;

    //Create the connection with the string URL and kick it off
    m_connectionPosts = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
    [m_connectionPosts start];
//    NSURLConnection
}

- (void) QueryAPIFeatures:(NSString *)url reset:(Boolean)doReset
{
    m_receivedDataFeatures = [[NSMutableData alloc] init];
    m_resetFeatures = doReset;
    m_lastURLFeatures = url;
    
    //Create the connection with the string URL and kick it off
    m_connectionFeatures = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
    [m_connectionFeatures start];
    //    NSURLConnection
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //Reset the data as this could be fired if a redirect or other response occurs
    if (connection == m_connectionPosts)
    {
        [m_receivedData setLength:0];
    }
    else if (connection == m_connectionFeatures)
    {
        [m_receivedDataFeatures setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //Append the received data each time this is called
    if (connection == m_connectionPosts)
    {
        [m_receivedData appendData:data];
    }
    else if (connection == m_connectionFeatures)
    {
        [m_receivedDataFeatures appendData:data];
    }
}

- (void)failedFeed
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FailedFeed" object:self];
    
    m_connectionPosts = nil;
    m_connectionFeatures = nil;
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Cannot connect to WIB"
                              message:@"Please ensure that you are connected to the internet."
                              delegate:self
                              cancelButtonTitle:@"Try Again"
                              otherButtonTitles:nil];
    [alertView show];
}

- (void)emptyFeed
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FailedFeed" object:self];
    
    m_connectionPosts = nil;
    m_connectionFeatures = nil;
    
    if (m_hasSearch)
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Search Failed"
                                  message:@"No hits for search term"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel Search"
                                  otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Cannot connect to WIB"
                                  message:@"Please ensure that you are connected to the internet."
                                  delegate:self
                                  cancelButtonTitle:@"Try Again"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [alertView cancelButtonIndex])
    {
        if (m_hasSearch)
        {
            [self clearSearch];
        }
        else
        {
            m_receivedData = [[NSMutableData alloc] init];
            m_receivedDataFeatures = [[NSMutableData alloc] init];
            
            m_connectionPosts = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:m_lastURLPosts]] delegate:self];
            m_connectionFeatures = [NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:m_lastURLFeatures]] delegate:self];

            [m_connectionPosts start];
            [m_connectionFeatures start];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (connection == m_connectionPosts)
    {
        [self failedFeed];
    }
    else if (connection == m_connectionFeatures)
    {
        [self failedFeed];
    }
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
 }

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    bool isPosts = (connection == m_connectionPosts);
    bool isFeatures = (connection == m_connectionFeatures);
    
    if (!isPosts && !isFeatures)
        return;
    
    NSMutableData *data = nil;
    if (isPosts)
    {
        m_connectionPosts = nil;
        data = m_receivedData;
    }
    else if (isFeatures)
    {
        m_connectionFeatures = nil;
        data = m_receivedDataFeatures;
    }
    
    //Start the XML parser with the delegate pointing at the current object
    NSError *errorRes = nil;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:data
                          options:kNilOptions
                          error:&errorRes];
    
    NSNumber *numItems = [json objectForKey:@"count"];
    if ((numItems.intValue > 0) || isFeatures)
    {
        NSMutableArray *pItems     = m_hasSearch ? m_searchItems : m_mainItems;
        NSMutableArray *pFeatures  = m_hasSearch ? m_searchFeatures : m_mainFeatures;

        if (isPosts && reset)
        {
            [pItems removeAllObjects];
        }
        else if (isFeatures && m_resetFeatures)
        {
            [pFeatures removeAllObjects];
        }

        if (isPosts)
        {
            NSNumber *pages = [json objectForKey:@"pages"];
            if (m_hasSearch)
            {
                m_searchTotalPages = pages.intValue;
            }
            else
            {
                m_mainTotalPages = pages.intValue;
            }

            numNewFront = 0;
            numNewBack = 0;
        }
    
        NSArray *posts = [json objectForKey:@"posts"];

        for (NSDictionary *post in posts)
        {
            NSNumber *postIdx = [post objectForKey:@"id"];
            bool skip = false;
            
            if (reset == false)
            {
                //--- Check for inserting new posts
                for (CRSSItem *oldPost in pItems)
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
                [newPost initWithDictionary:post isFeature:!isPosts];
            
                if (m_insertFront)
                {
                    if (isPosts)
                    {
                        [pItems insertObject:newPost atIndex:numNewFront];
                        numNewFront++;
                    }
                    else
                    {
                        [pFeatures insertObject:newPost atIndex:numNewFront];
                    }
                }
                else
                {
                    if (isPosts)
                    {
                        [pItems addObject:newPost];
                        numNewBack++;
                    }
                    else
                    {
                        [pFeatures addObject:newPost];
                    }
                }
            }
        }
        
        if ((m_connectionPosts == nil) && (m_connectionFeatures == nil))
        {
            [self UpdateFilteredItems];
        }
    }
    else if (isPosts)
    {
        [self emptyFeed];
    }
    
    //--- Free up our buffer
    [data setLength:0];
}

- (void) LoadFeed
{
    NSString *url = SERVER_POSTS_URL;
    NSString *urlFeatures = SERVER_FEATURES_URL;
    m_lastSearch = url;
    m_insertFront = false;
    [self QueryAPI:url reset:true];
    [self QueryAPIFeatures:urlFeatures reset:true];
    m_mainPage = 0;
    m_hasSearch = false;
}

- (void) Search:(NSString *)filter
{
    NSString *url = [SERVER_SEARCH_POSTS_URL stringByAppendingString:filter];
    NSString *urlFeatures = [SERVER_SEARCH_FEATURES_URL stringByAppendingString:filter];
    m_lastSearch = url;
    m_insertFront = false;
    
    [self QueryAPI:url reset:true];
    [self QueryAPIFeatures:urlFeatures reset:true];
    m_searchPage = 0;
    m_hasSearch = true;
}

- (int) GetPage
{
    return (m_hasSearch) ? m_searchPage : m_mainPage;
}
- (int) GetNumPages
{
    return (m_hasSearch) ? m_searchTotalPages : m_mainTotalPages;
}


- (void) LoadPage:(int) pageNum
{
    NSString *url = [m_lastSearch stringByAppendingFormat:@"&page=%d",pageNum+1];
    [self QueryAPI:url reset:false];
    if (m_hasSearch)
    {
        m_insertFront = pageNum <= m_searchPage;
        m_searchPage = pageNum;
    }
    else
    {
        m_insertFront = pageNum <= m_mainPage;
        m_mainPage = pageNum;
    }
}

- (void) clearSearch
{
    if (m_hasSearch)
    {
        NSString *url = SERVER_POSTS_URL;
        m_lastSearch = url;
        
        m_hasSearch = false;
        
        [m_connectionPosts cancel];
        [m_connectionFeatures cancel];
        m_connectionPosts = nil;
        m_connectionFeatures = nil;
        
        [m_searchItems removeAllObjects];
        [m_searchFeatures removeAllObjects];

        reset = true;

        [self UpdateFilteredItems];
        
    }
}

- (NSArray *) items
{
    return m_filteredItems;
}

- (NSArray *) features
{
    return m_filteredFeatures;
}



@end
