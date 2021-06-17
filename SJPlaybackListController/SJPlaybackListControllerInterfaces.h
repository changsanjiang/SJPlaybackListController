//
//  SJPlaybackListControllerInterfaces.h
//  SJPlaybackListController
//
//  Created by 蓝舞者 on 2021/6/17.
//  Copyright © 2021 changsanjiang@gmail.com. All rights reserved.
//

#ifndef SJPlaybackListControllerInterfaces_h
#define SJPlaybackListControllerInterfaces_h

#import "SJPlaybackListControllerDefines.h"
@protocol SJPlaybackListControllerDelegate, SJPlaybackListControllerObserver;

NS_ASSUME_NONNULL_BEGIN
@protocol SJPlaybackListController <NSObject>

@property (nonatomic, weak, readonly, nullable) id<SJPlaybackListControllerDelegate> delegate;

// observer

- (void)registerObserver:(id<SJPlaybackListControllerObserver>)observer;
- (void)removeObserver:(id<SJPlaybackListControllerObserver>)observer;

// items

@property (nonatomic, readonly) NSInteger numberOfItems;
- (nullable id)itemAtIndex:(NSInteger)index;
- (NSInteger)indexOfItem:(id)item;

- (void)addItem:(id)item;
- (void)addItemsFromArray:(NSArray *)items;
- (void)insertItem:(id)item atIndex:(NSInteger)index;

- (void)removeAllItems;
- (void)removeItemAtIndex:(NSInteger)index;

- (void)enumerateItemsUsingBlock:(void(NS_NOESCAPE ^)(id item, NSInteger index, BOOL *stop))block;

// playback mode

@property (nonatomic, readonly) SJPlaybackMode mode;
@property (nonatomic, readonly) SJPlaybackModeMask supportedModes;
- (void)switchToMode:(SJPlaybackMode)mode;
- (void)switchMode;
 
@property (nonatomic, readonly, getter=isInfiniteListLoop) BOOL infiniteListLoop;

// playback control

@property (nonatomic, readonly) NSInteger curIndex;
- (void)playItemAtIndex:(NSInteger)index;
- (void)playNextItem;
- (void)playPreviousItem;

// callback

- (void)currentItemFinishedPlaying;
@end

@protocol SJPlaybackListControllerDelegate <NSObject>
- (void)playbackListController:(id<SJPlaybackListController>)controller needPlayItemAtIndex:(NSInteger)index;
- (void)playbackListControllerNeedReplayCurrentItem:(id<SJPlaybackListController>)controller;
@end

@protocol SJPlaybackListControllerObserver <NSObject>
@optional
- (void)playbackListController:(id<SJPlaybackListController>)controller didPlayItemAtIndex:(NSInteger)index;
- (void)playbackListController:(id<SJPlaybackListController>)controller modeDidChange:(SJPlaybackMode)mode;
- (void)playbackListController:(id<SJPlaybackListController>)controller didAddItemAtIndex:(NSInteger)index;
- (void)playbackListController:(id<SJPlaybackListController>)controller didAddItemsAtIndexes:(NSIndexSet *)indexes;
- (void)playbackListController:(id<SJPlaybackListController>)controller didInsertItemAtIndex:(NSInteger)index;
- (void)playbackListControllerDidRemoveAllItems:(id<SJPlaybackListController>)controller;
- (void)playbackListController:(id<SJPlaybackListController>)controller didRemoveItemAtIndex:(NSInteger)index;
@end
NS_ASSUME_NONNULL_END

#endif /* SJPlaybackListControllerInterfaces_h */
