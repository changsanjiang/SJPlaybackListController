//
//  SJPlaybackListController.h
//  SJPlaybackListController_Example
//
//  Created by 蓝舞者 on 2021/6/17.
//  Copyright © 2021 changsanjiang@gmail.com. All rights reserved.
//

#import "SJPlaybackListControllerInterfaces.h"

NS_ASSUME_NONNULL_BEGIN

@interface SJPlaybackListController<ItemType> : NSObject<SJPlaybackListController>
- (instancetype)initWithDelegate:(nullable id<SJPlaybackListControllerDelegate>)delegate;

@property (nonatomic, weak, nullable) id<SJPlaybackListControllerDelegate> delegate;

// observer

- (void)registerObserver:(id<SJPlaybackListControllerObserver>)observer;
- (void)removeObserver:(id<SJPlaybackListControllerObserver>)observer;

// items

@property (nonatomic, readonly) NSInteger numberOfItems;
- (nullable ItemType)itemAtIndex:(NSInteger)index;
- (NSInteger)indexOfItem:(id)item;

- (void)addItem:(ItemType)item;
- (void)addItemsFromArray:(NSArray<ItemType> *)items;
- (void)insertItem:(ItemType)item atIndex:(NSInteger)index;

- (void)removeAllItems;
- (void)removeItemAtIndex:(NSInteger)index;

- (void)enumerateItemsUsingBlock:(void(NS_NOESCAPE ^)(ItemType item, NSInteger index, BOOL *stop))block;

// playback mode

@property (nonatomic, readonly) SJPlaybackMode mode;
@property (nonatomic) SJPlaybackModeMask supportedModes;
- (void)switchToMode:(SJPlaybackMode)mode;
- (void)switchMode;
 
@property (nonatomic, getter=isInfiniteListLoop) BOOL infiniteListLoop;

// playback control

@property (nonatomic, readonly) NSInteger curIndex;
- (void)playItemAtIndex:(NSInteger)index;
- (void)playNextItem;
- (void)playPreviousItem;
 
@property (nonatomic, readonly) BOOL isWaitingToPlaybackEnds;
- (void)finishPlayback;
- (void)cancelPlayback;
@end

NS_ASSUME_NONNULL_END
