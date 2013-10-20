//
//  UserData.m
//  testapp
//
//  Created by Jose Lopes on 19/10/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import "UserData.h"
#import "CRSSItem.h"

@implementation UserData
{
    id<FavouritesChangedDelegate> m_listener;
}

static UserData *s_userData;

@synthesize favourites;

- (id) init
{
    favourites = [[NSMutableSet alloc] init];
    
    [self load];
    
    return self;
}

+ (UserData*) get
{
    if (s_userData == NULL)
    {
        s_userData = [[UserData alloc] init];
    }
    return s_userData;
}

- (void) addListener:(id<FavouritesChangedDelegate>) listener
{
    m_listener = listener;
}

- (void)onChanged
{
    [m_listener onFavouritesChanged];
}

- (NSString *) saveFilePath
{
	NSArray *path =	NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
	return [[path objectAtIndex:0] stringByAppendingPathComponent:@"userdata.plist"];
}

- (void) save
{
    NSMutableArray *favouriteIDs = [[NSMutableArray alloc] init];

    NSArray *favouriteList = [self.favourites allObjects];
    for( CRSSItem *item in favouriteList)
    {
        [favouriteIDs addObject:[NSNumber numberWithInt:item.postID]];
        [favouriteIDs addObject:item.title];
    }
    
	[favouriteIDs writeToFile:[self saveFilePath] atomically:YES];
}

-(void) load
{
    NSString *myPath = [self saveFilePath];
    
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:myPath];
    
    [favourites removeAllObjects];
	if (fileExists)
	{
		NSArray *values = [[NSArray alloc] initWithContentsOfFile:myPath];
        int numFavourites = values.count/2;
        for (int i=0; i<numFavourites; i++)
        {
            NSNumber *postId = [values objectAtIndex:2*i];
            NSString *postTitle = [values objectAtIndex:(2*i)+1];
            
            CRSSItem *item = [[CRSSItem alloc] init];
            item.postID = [postId integerValue];
            item.title = postTitle;
            item.requiresDownload = true;
            
            [favourites addObject:item];
        }
	}
}

@end
