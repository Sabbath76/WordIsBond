//
//  RSSParser.m
//  testapp
//
//  Created by Jose Lopes on 31/03/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "RSSParser.h"


@interface RSSParser ()
@property (nonatomic, copy) ArrayBlock m_completionHandler;
@end


@implementation RSSParser

@synthesize m_completionHandler;

- (void)startParse:(NSString *)url completionHandler:(ArrayBlock)handler
{
    //Set the status to parsing
    m_parsing = true;
    
    m_completionHandler = handler;
    
    //Initialise the receivedData object
    m_receivedData = [[NSMutableData alloc] init];
    
    m_allItems = [[NSMutableArray alloc] init];
    
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
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:m_receivedData];
    [parser setDelegate:self];
    [parser parse];
    
    m_parsing = false;
    
    self.m_completionHandler(m_allItems);
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    //Create the property map that will be used to check and populate from elements
    m_propertyMap = [[NSMutableArray alloc] initWithObjects:@"title", @"description", nil];
    //Clear allItems each time we kick off a new parse
    [m_allItems removeAllObjects];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    //If we find an item element, then ensure that the object knows we are inside it, and that the new item is allocated
    if ([elementName isEqualToString:@"item"])
    {
        m_currentItem = [[CRSSItem alloc] init];
        m_inItemElement = true;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    //When we reach the end of an item element, we should add the RSSItem to the allItems array
    if ([elementName isEqualToString:@"item"])
    {
        [m_currentItem setup];
        [m_allItems addObject:m_currentItem];
//        [m_currentItem release];
        m_currentItem = nil;
        m_inItemElement = false;
    }
    //If we are in element and we reach the end of an element in the propertyMap, we can trim its value and set it using the setValue method on RSSItem
    if (m_inItemElement)
    {
        if ([m_propertyMap containsObject:elementName])
        {
            [m_currentItem setValue:[m_currentValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:elementName];
        }
    }
    
    //If we've reached the end of an element then we should the scrap the value regardless of whether we've used it
//    [m_currentValue release];
    m_currentValue = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    //When we find characters inside an element, we can add it to the current value, which is created if it is not initialized at present
    if (!m_currentValue)
    {
        m_currentValue = [[NSMutableString alloc] init];
    }
    [m_currentValue appendString:string];
}

@end
