//
//  SJPlaybackListController.m
//  SJPlaybackListController_Example
//
//  Created by 蓝舞者 on 2021/6/17.
//  Copyright © 2021 changsanjiang@gmail.com. All rights reserved.
//

#import "SJPlaybackListController.h"

@interface SJPlaybackListController () {
    NSMutableArray *_items;
    NSInteger _curIndex;
    dispatch_semaphore_t _semaphore;
    SJPlaybackModeMask _supportedModes;
    SJPlaybackMode _mode;
    BOOL _infiniteListLoop;
    BOOL _isWaitingToPlaybackEnds;
    id<SJPlaybackListControllerDelegate> _delegate;
}
@property (nonatomic) SJPlaybackMode mode;
@end

@implementation SJPlaybackListController {
    NSHashTable<id<SJPlaybackListControllerObserver>> *_observers;
}

- (instancetype)initWithDelegate:(nullable id<SJPlaybackListControllerDelegate>)delegate {
    self = [super init];
    if ( self ) {
        _delegate = delegate;
        _items = NSMutableArray.array;
        _supportedModes = SJPlaybackModeMaskAll;
        _curIndex = NSNotFound;
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (void)setDelegate:(nullable id<SJPlaybackListControllerDelegate>)delegate {
    [self _lockInBlock:^{
        if ( delegate != _delegate ) {
            _delegate = delegate;
        }
    }];
}

- (nullable id<SJPlaybackListControllerDelegate>)delegate {
    __block id<SJPlaybackListControllerDelegate> delegate;
    [self _lockInBlock:^{
        delegate = _delegate;
    }];
    return delegate;
}

- (void)registerObserver:(id<SJPlaybackListControllerObserver>)observer {
    if ( observer != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( self->_observers == nil ) {
                self->_observers = [NSHashTable weakObjectsHashTable];
            }
            [self->_observers addObject:observer];
        });
    }
}

- (void)removeObserver:(id<SJPlaybackListControllerObserver>)observer {
    if ( observer != nil ) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_observers removeObject:observer];
        });
    }
}

- (NSInteger)numberOfItems {
    __block NSInteger count = 0;
    [self _lockInBlock:^{
        count = _items.count;
    }];
    return count;
}

- (nullable id)itemAtIndex:(NSInteger)index {
    __block id item = nil;
    [self _lockInBlock:^{
        item = [self _itemAtIndex:index];
    }];
    return item;
}

- (NSInteger)indexOfItem:(id)item {
    if ( item != nil ) {
        __block NSInteger idx = NSNotFound;
        [self _lockInBlock:^{
            idx = [_items indexOfObject:item];
        }];
        return idx;
    }
    return NSNotFound;
}
 
- (void)addItem:(id)item {
    if ( item != nil ) {
        [self _lockInBlock:^{
            NSInteger idx = _items.count;
            [_items addObject:item];
            if ( _curIndex == NSNotFound ) {
                _curIndex = 0;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
                    if ( [observer respondsToSelector:@selector(playbackListController:didAddItemAtIndex:)] ) {
                        [observer playbackListController:self didAddItemAtIndex:idx];
                    }
                }];
            });
        }];
    }
}

- (void)addItemsFromArray:(NSArray *)items {
    if ( items.count != 0 ) {
        [self _lockInBlock:^{
            NSInteger idx = _items.count;
            [_items addObjectsFromArray:items];
            if ( _curIndex == NSNotFound ) {
                _curIndex = 0;
            }
            NSIndexSet *indexes = [NSIndexSet.alloc initWithIndexesInRange:NSMakeRange(idx, items.count)];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
                    if ( [observer respondsToSelector:@selector(playbackListController:didAddItemsAtIndexes:)] ) {
                        [observer playbackListController:self didAddItemsAtIndexes:indexes];
                    }
                }];
            });
        }];
    }
}

- (void)insertItem:(id)item atIndex:(NSInteger)paramIndex {
    [self _lockInBlock:^{
        if ( item != nil && [self _isSafeIndexForInserting:paramIndex] ) {
            [_items insertObject:item atIndex:paramIndex];
            if ( _curIndex == NSNotFound ) {
                _curIndex = 0;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
                    if ( [observer respondsToSelector:@selector(playbackListController:didInsertItemAtIndex:)] ) {
                        [observer playbackListController:self didInsertItemAtIndex:paramIndex];
                    }
                }];
            });
        }
    }];
}

- (void)removeAllItems {
    [self _lockInBlock:^{
        if ( _items.count != 0 ) {
            [_items removeAllObjects];
            _isWaitingToPlaybackEnds = NO;
            _curIndex = NSNotFound;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate needStopPlaybackWithPlaybackListController:self];
                [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
                    if ( [observer respondsToSelector:@selector(playbackListControllerDidRemoveAllItems:)] ) {
                        [observer playbackListControllerDidRemoveAllItems:self];
                    }
                }];
            });
        }
    }];
}
- (void)removeItemAtIndex:(NSInteger)paramIndex {
    [self _lockInBlock:^{
        if ( [self _isSafeIndexForGetting:paramIndex] ) {
            BOOL needsStopPlayback = NO;
            [_items removeObjectAtIndex:paramIndex];
            if      ( _items.count == 0 ) {
                _isWaitingToPlaybackEnds = NO;
                _curIndex = NSNotFound;
                needsStopPlayback = YES;
            }
            // 如果删除的是当前的item
            else if ( _curIndex == paramIndex ) {
                BOOL isLastItem = _curIndex == _items.count - 1;
                if ( isLastItem  ) {
                    _curIndex = 0;
                    if ( _isWaitingToPlaybackEnds )
                        _isWaitingToPlaybackEnds = _infiniteListLoop;
                }
                
                if ( _isWaitingToPlaybackEnds ) {
                    [self _playItemAtIndex:_curIndex];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( needsStopPlayback ) {
                    [self.delegate needStopPlaybackWithPlaybackListController:self];
                }
                [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
                    if ( [observer respondsToSelector:@selector(playbackListController:didRemoveItemAtIndex:)] ) {
                        [observer playbackListController:self didRemoveItemAtIndex:paramIndex];
                    }
                }];
            });
        }
    }];
}

- (void)enumerateItemsUsingBlock:(void(NS_NOESCAPE ^)(id item, NSInteger index, BOOL *stop))block {
    __block NSArray *items = nil;
    [self _lockInBlock:^{
        items = _items.copy;
    }];
    [items enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, idx, stop);
    }];
}

- (SJPlaybackMode)mode {
    __block SJPlaybackMode mode = 0;
    [self _lockInBlock:^{
        mode = _mode;
    }];
    return mode;
}

- (void)setSupportedModes:(SJPlaybackModeMask)supportedModes {
    NSParameterAssert(supportedModes != 0);
    NSParameterAssert(supportedModes <= SJPlaybackModeMaskAll);
    [self _lockInBlock:^{
        _supportedModes = supportedModes;
    }];
}

- (SJPlaybackModeMask)supportedModes {
    __block SJPlaybackModeMask supportedModes = 0;
    [self _lockInBlock:^{
        supportedModes = _supportedModes;
    }];
    return supportedModes;
}

- (void)switchToMode:(SJPlaybackMode)mode {
    [self _lockInBlock:^{
        if ( [self _isModeSupported:mode] ) {
            [self _switchToMode:mode];
        }
    }];
}

- (void)switchMode {
    [self _lockInBlock:^{
        SJPlaybackMode mode = _mode;
        if ( _supportedModes == (1 << mode) ) return;
        
        do {
            mode = (mode + 1) % 3;
        } while ( ![self _isModeSupported:mode] );
        [self _switchToMode:mode];
    }];
}

- (void)setInfiniteListLoop:(BOOL)infiniteListLoop {
    [self _lockInBlock:^{
        _infiniteListLoop = infiniteListLoop;
    }];
}

- (BOOL)isInfiniteListLoop {
    __block BOOL infiniteListLoop = NO;
    [self _lockInBlock:^{
        infiniteListLoop = _infiniteListLoop;
    }];
    return infiniteListLoop;
}

- (NSInteger)curIndex {
    __block NSInteger idx = 0;
    [self _lockInBlock:^{
        idx = _curIndex;
    }];
    return idx;
}

- (void)playItemAtIndex:(NSInteger)index {
    [self _lockInBlock:^{
        [self _playItemAtIndex:index];
    }];
}

- (void)playCurrentItem {
    [self _lockInBlock:^{
        [self _playItemAtIndex:_curIndex];
    }];
}

- (void)playNextItem {
    [self _lockInBlock:^{
        [self _playNextItem];
    }];
}

- (void)playPreviousItem {
    [self _lockInBlock:^{
        NSInteger count = _items.count;
        
       if ( count == 0 )
           return;
        
        if ( _items.count == 1 && _curIndex != NSNotFound ) {
            [self _replay];
            return;
        }
        
        if ( _mode == SJPlaybackModeShuffle ) {
            [self _shufflePlay];
            return;
        }
        
        NSInteger previousIdx = _curIndex != NSNotFound ? (_curIndex - 1) : 0;
        if ( previousIdx == -1 && _infiniteListLoop ) {
            previousIdx = count - 1;
        }
        [self _playItemAtIndex:previousIdx];
    }];
}

- (void)replaceItemsFromArray:(NSArray *)items {
    if ( items.count == 0 ) {
        [self removeAllItems];
        return;
    }
    
    [self _lockInBlock:^{
        id curItem = [self _itemAtIndex:_curIndex];
        NSInteger index = NSNotFound;
        if ( curItem != nil ) {
            index = [items indexOfObject:curItem];
        }
        BOOL isExists = index != NSNotFound;
        NSInteger curIndex = isExists ? index : 0;
        [_items removeAllObjects];
        [_items addObjectsFromArray:items];
        _curIndex = curIndex;
        
        if ( !isExists && _isWaitingToPlaybackEnds ) {
            _isWaitingToPlaybackEnds = NO;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
                if ( [observer respondsToSelector:@selector(playbackListController:didReplaceItemsWithIndexes:)] ) {
                    [observer playbackListController:self didReplaceItemsWithIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, items.count)]];
                }
            }];
        });
    }];
}

- (BOOL)isWaitingToPlaybackEnds {
    __block BOOL isWaitingToPlaybackEnds;
    [self _lockInBlock:^{
        isWaitingToPlaybackEnds = _isWaitingToPlaybackEnds;
    }];
    return isWaitingToPlaybackEnds;
}

- (void)finishPlayback {
    [self _lockInBlock:^{
        if ( _items.count == 0 || !_isWaitingToPlaybackEnds )
            return;
        
        if ( _mode == SJPlaybackModeRepeatOne ) {
            [self _replay];
            return;
        }
        
        if ( !_infiniteListLoop && _curIndex == _items.count - 1 ) {
            _isWaitingToPlaybackEnds = NO;
            return;
        }
        
        [self _playNextItem];
    }];
}

- (void)cancelPlayback {
    [self _lockInBlock:^{
        _isWaitingToPlaybackEnds = NO;
    }];
}

#pragma mark -

- (void)_lockInBlock:(void(NS_NOESCAPE ^)(void))block {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    block();
    dispatch_semaphore_signal(_semaphore);
}

- (BOOL)_isSafeIndexForGetting:(NSInteger)index {
    return index >= 0 && index < _items.count;
}

- (BOOL)_isSafeIndexForInserting:(NSInteger)index {
    return index >= 0 && index <= _items.count;
}

- (BOOL)_isModeSupported:(SJPlaybackMode)mode {
    return (1 << mode) & _supportedModes;
}

- (void)_enumerateObserversUsingBlock:(void(NS_NOESCAPE ^)(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop))block {
    if ( _observers.count != 0 ) {
        [NSAllHashTableObjects(_observers) enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            block(obj, idx, stop);
        }];
    }
}

- (void)_switchToMode:(SJPlaybackMode)mode {
    if ( mode != _mode ) {
        _mode = mode;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
                if ( [observer respondsToSelector:@selector(playbackListController:modeDidChange:)] ) {
                    [observer playbackListController:self modeDidChange:mode];
                }
            }];
        });
    }
}

- (void)_shufflePlay {
    if ( _items.count == 1 ) {
        [self _playItemAtIndex:0];
        return;
    }
    
    NSInteger nextIdx = 0;
    do {
        nextIdx = arc4random() % _items.count;
    } while ( nextIdx == _curIndex);
    [self _playItemAtIndex:nextIdx];
}

- (void)_playItemAtIndex:(NSInteger)index {
    NSAssert(_delegate != nil, @"The delegate can't be nil!");
    
    id item = [self _isSafeIndexForGetting:index] ? [_items objectAtIndex:index] : nil;
    if ( item == nil ) return;
    _curIndex = index;
    _isWaitingToPlaybackEnds = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate playbackListController:self needPlayItemAtIndex:index];
        [self _enumerateObserversUsingBlock:^(id<SJPlaybackListControllerObserver> observer, NSInteger index, BOOL *stop) {
            if ( [observer respondsToSelector:@selector(playbackListController:didPlayItemAtIndex:)] ) {
                [observer playbackListController:self didPlayItemAtIndex:index];
            }
        }];
    });
}

- (void)_replay {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate needReplayForCurrentItemWithPlaybackListController:self];
    });
}

- (void)_playNextItem {
    NSInteger count = _items.count;
    
   if ( count == 0 )
       return;
    
    if ( _items.count == 1 && _curIndex != NSNotFound ) {
        [self _replay];
        return;
    }
    
    if ( _mode == SJPlaybackModeShuffle ) {
        [self _shufflePlay];
        return;
    }
    
    NSInteger nextIdx = _curIndex != NSNotFound ? (_curIndex + 1) : 0;
    if ( nextIdx == count && _infiniteListLoop ) {
        nextIdx = 0;
    }
    [self _playItemAtIndex:nextIdx];
}

- (nullable id)_itemAtIndex:(NSInteger)index {
    return [self _isSafeIndexForGetting:index] ? [_items objectAtIndex:index] : nil;
}
@end
