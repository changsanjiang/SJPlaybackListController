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

/// 当前item的索引
///
/// 索引值随以下状态发生变化:
///     - 列表为空时, 将被设置为: NSNotFound
///     - 添加新的item时: 如果添加之前列表为空, 则在添加之后索引值将被设置为: 0
///     - 移除当前播放的item时, 此item如果是lastItem, 则索引将被设置为: 0
///     - 切换item时, 将会设置为对应item的索引
///     - 替换列表的操作, 请查看`replaceItemsFromArray:`
///
@property (nonatomic, readonly) NSInteger curIndex;
- (void)playItemAtIndex:(NSInteger)index;
- (void)playCurrentItem;
- (void)playNextItem;
- (void)playPreviousItem;

/// 替换操作
///
///     对curIndex索引的设置:
///         - curItem如果在`items`中, 则替换后的curIndex将变为新的索引值, 将保持当前等待状态
///         - 否则会被设置为0. 等待状态将会被取消
///
- (void)replaceItemsFromArray:(NSArray *)items;

/// 是否等待播放完毕
///
@property (nonatomic, readonly) BOOL isWaitingToPlaybackEnds;
- (void)finishPlayback;
- (void)cancelPlayback;
@end

@protocol SJPlaybackListControllerDelegate <NSObject>
- (void)playbackListController:(id<SJPlaybackListController>)controller needPlayItemAtIndex:(NSInteger)index;
- (void)needReplayForCurrentItemWithPlaybackListController:(id<SJPlaybackListController>)controller;
- (void)needStopPlaybackWithPlaybackListController:(id<SJPlaybackListController>)controller;
@end

@protocol SJPlaybackListControllerObserver <NSObject>
@optional
- (void)playbackListController:(id<SJPlaybackListController>)controller didPlayItemAtIndex:(NSInteger)index;
- (void)playbackListController:(id<SJPlaybackListController>)controller modeDidChange:(SJPlaybackMode)mode;
- (void)playbackListController:(id<SJPlaybackListController>)controller didAddItemAtIndex:(NSInteger)index;
- (void)playbackListController:(id<SJPlaybackListController>)controller didAddItemsAtIndexes:(NSIndexSet *)indexes;
- (void)playbackListController:(id<SJPlaybackListController>)controller didInsertItemAtIndex:(NSInteger)index;
- (void)playbackListController:(id<SJPlaybackListController>)controller didReplaceItemsWithIndexes:(NSIndexSet *)indexes;
- (void)playbackListControllerDidRemoveAllItems:(id<SJPlaybackListController>)controller;
- (void)playbackListController:(id<SJPlaybackListController>)controller didRemoveItemAtIndex:(NSInteger)index;
@end
NS_ASSUME_NONNULL_END

#endif /* SJPlaybackListControllerInterfaces_h */
