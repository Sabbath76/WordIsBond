//
//  UserData.h
//  testapp
//
//  Created by Jose Lopes on 19/10/2013.
//  Copyright (c) 2013 Tom Berry. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FavouritesChangedDelegate;

@interface UserData : NSObject

@property (nonatomic, retain) NSMutableArray *favourites;

+ (UserData*) get;
- (void)addListener:(id<FavouritesChangedDelegate>) listener;
- (void)onChanged;
- (void)save;
- (void)load;
- (int)getTargetPost;
- (void)setTargetPost:(int)postID;

@end


@protocol FavouritesChangedDelegate

- (void)onFavouritesChanged;

@end


@interface UIColor (CustomColors)

+ (UIColor *)wibColour;
+ (UIColor *)wibTintColour;

@end
