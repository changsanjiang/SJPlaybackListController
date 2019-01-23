//
//  SJPlaybackListController.m
//  Pods-SJPlaybackListController_Example
//
//  Created by BlueDancer on 2019/1/23.
//

#import "SJPlaybackListController.h"
#import "SJPlaybackListControllerObserver.h"
#if __has_include(<SJBaseVideoPlayer/SJBaseVideoPlayer.h>)
#import <SJBaseVideoPlayer/SJBaseVideoPlayer.h>
#else
#import "SJBaseVideoPlayer.h"
#endif

NS_ASSUME_NONNULL_BEGIN
#define SJPlaybackListControllerLock() dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
#define SJPlaybackListControllerUnlock() dispatch_semaphore_signal(_lock);

@interface SJPlaybackListController ()
@property (nonatomic, strong, readonly) id<SJPlayStatusObserver> playStatusObserver;
@property (nonatomic, strong, readonly) NSMutableArray<id<SJMediaInfo>> *m;
@property (strong, nullable) id<SJMediaInfo> currentMedia;
@end

@implementation SJPlaybackListController {
    dispatch_semaphore_t _lock;
}
@synthesize supportedMode = _supportedMode;

- (instancetype)initWithPlayer:(__kindof SJBaseVideoPlayer *)player {
    self = [super init];
    if (self) {
        _player = player;
        _m = [NSMutableArray array];
        _lock = dispatch_semaphore_create(1);
        _supportedMode = SJSupportedPlaybackMode_All;
        [self initializePlayStatusObserver];
    }
    return self;
}

- (id<SJPlaybackListControllerObserver>)getObserver {
    return [[SJPlaybackListControllerObserver alloc] initWithListController:self];
}

#pragma mark -

- (NSInteger)indexForMediaId:(NSInteger)mediaId {
    SJPlaybackListControllerLock();
    NSInteger idx = [self _indexForMediaId:mediaId];
    SJPlaybackListControllerUnlock();
    return idx;
}

- (nullable id<SJMediaInfo>)mediaAtIndex:(NSInteger)index {
    id<SJMediaInfo> info = nil;
    SJPlaybackListControllerLock();
    if ( index >= 0 && index < _m.count ) {
        info = _m[index];
    }
    SJPlaybackListControllerUnlock();
    return info;
}

- (void)replaceMedias:(NSArray<id<SJMediaInfo>> *)medias {
    if ( 0 == medias.count )
        return;
    SJPlaybackListControllerLock();
    [_m removeAllObjects];
    [_m addObjectsFromArray:medias];
    SJPlaybackListControllerUnlock();
    [NSNotificationCenter.defaultCenter postNotificationName:SJPlaybackListControllerListDidChangeNotification object:self];
}

- (void)addMedia:(id<SJMediaInfo>)media {
    if ( !media )
        return;
    SJPlaybackListControllerLock();
    NSInteger idx = [self _indexForMediaId:media.id];
    if ( idx != NSNotFound ) {
        [_m removeObjectAtIndex:idx];
    }
    [_m addObject:media];
    SJPlaybackListControllerUnlock();
    [NSNotificationCenter.defaultCenter postNotificationName:SJPlaybackListControllerListDidChangeNotification object:self];
}

- (void)removeAllMedias {
    SJPlaybackListControllerLock();
    [_m removeAllObjects];
    SJPlaybackListControllerUnlock();
    [NSNotificationCenter.defaultCenter postNotificationName:SJPlaybackListControllerListDidChangeNotification object:self];
}

- (NSArray<id<SJMediaInfo>> *)medias {
    SJPlaybackListControllerLock();
    NSArray<id<SJMediaInfo>> *medias = _m.copy;
    SJPlaybackListControllerUnlock();
    return medias;
}

#pragma mark -

- (void)changePlaybackMode {
    if ( self.supportedMode == SJSupportedPlaybackMode_ListCycle ) return;
    if ( self.supportedMode == SJSupportedPlaybackMode_RandomPlay ) return;
    if ( self.supportedMode == SJSupportedPlaybackMode_SingleCycle ) return;
    SJPlaybackMode mode = self.mode;
    while ( !(self.supportedMode & (mode += 1) % 3) ) { }
    self.mode = mode;
}

@synthesize mode = _mode;
- (void)setMode:(SJPlaybackMode)mode {
    @synchronized (self) {
        if ( mode == _mode )
            return;
        _mode = mode;
        [NSNotificationCenter.defaultCenter postNotificationName:SJPlaybackListControllerPlaybackModeDidChangeNotification object:self];
    }
}
- (SJPlaybackMode)mode {
    @synchronized(self) {
        return _mode;
    }
}

- (void)playPreviousMedia {
    if ( 0 == _m.count )
        return;
    NSInteger idx = [self indexForMediaId:self.currentMedia.id];
    [self playAtIndex:(idx+1<_m.count)?idx+1:0];
}
- (void)playNextMedia {
    if ( 0 == _m.count )
        return;
    NSInteger idx = [self indexForMediaId:self.currentMedia.id];
    [self playAtIndex:(idx-1<_m.count)?idx-1:0];
}
- (void)playAtIndex:(NSInteger)idx {
    id<SJMediaInfo>_Nullable info = [self mediaAtIndex:idx];
    if ( !info || !info.asset )
        return;
    self.currentMedia = info;
    self.player.URLAsset = info.asset;
    [NSNotificationCenter.defaultCenter postNotificationName:SJPlaybackListControllerPrepareToPlayMediaNotification object:self];
}

#pragma mark -

- (NSInteger)_indexForMediaId:(NSInteger)mediaId {
    NSInteger idx = NSNotFound;
    for ( NSInteger i = 0 ; i < _m.count ; ++ i ) {
        id<SJMediaInfo> info = _m[i];
        if ( info.id == mediaId ) {
            idx = i;
            break;
        }
    }
    return idx;
}

#pragma mark -

- (void)initializePlayStatusObserver {
    _playStatusObserver = [_player getPlayStatusObserver];
    
    __weak typeof(self) _self = self;
    _playStatusObserver.playStatusDidChangeExeBlock = ^(SJBaseVideoPlayer * _Nonnull player) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self.mode == SJPlaybackMode_SingleCycle ) {
            [player replay];
        }
        else {
            [self playNextMedia];
        }
    };
}
@end
NS_ASSUME_NONNULL_END
