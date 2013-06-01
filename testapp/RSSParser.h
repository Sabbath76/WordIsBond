//
//  RSSParser.h
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRSSItem.h"

typedef void (^ArrayBlock)(NSArray *);

@interface RSSParser : NSObject <NSXMLParserDelegate>
{
    ArrayBlock      m_completionHandler;
    
    //This variable will eventually (once the asynchronous event has completed) hold all the RSSItems in the feed
    NSMutableArray *m_allItems;
    
    //This variable will be used to map properties in the XML to properties in the RSSItem object
    NSMutableArray *m_propertyMap;
    
    //This variable will be used to build up the data coming back from NSURLConnection
    NSMutableData *m_receivedData;
    
    //This item will be declared and created each time a new RSS item is encountered in the XML
    CRSSItem *m_currentItem;
    
    //This stores the value of the XML element that is currently being processed
    NSMutableString *m_currentValue;
    
    //This allows the creating object to know when parsing has completed
    BOOL m_parsing;
    
    //This internal variable allows the object to know if the current property is inside an item element
    BOOL m_inItemElement;
}


//This method kicks off a parse of a URL at a specified string
- (void)startParse:(NSString*)url completionHandler:(ArrayBlock)handler;

@end
