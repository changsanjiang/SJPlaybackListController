//
//  SJPlaybackListControllerProtocol.h
//  Pods
//
//  Created by BlueDancer on 2019/1/23.
//

#ifndef SJPlaybackListControllerProtocol_h
#define SJPlaybackListControllerProtocol_h

@protocol SJMediaInfo, SJPlaybackListControllerObserver;
@class SJVideoPlayerURLAsset, SJBaseVideoPlayer;

typedef enum : NSUInteger {
    SJPlaybackMode_ListCycle,       // 列表循环
    SJPlaybackMode_SingleCycle,     // 单曲循环
    SJPlaybackMode_RandomPlay,      // 随机播放
} SJPlaybackMode;

typedef enum : NSUInteger {
    SJSupportedPlaybackMode_ListCycle = 1 << 0,
    SJSupportedPlaybackMode_SingleCycle = 1 << 1,
    SJSupportedPlaybackMode_RandomPlay = 1 << 2,
    SJSupportedPlaybackMode_All = SJSupportedPlaybackMode_ListCycle | SJSupportedPlaybackMode_SingleCycle | SJSupportedPlaybackMode_RandomPlay,
} SJSupportedPlaybackMode;

NS_ASSUME_NONNULL_BEGIN
@protocol SJPlaybackListController <NSObject>
- (id<SJPlaybackListControllerObserver>)getObserver;

- (NSInteger)indexForMediaId:(NSInteger)mediaId; // 如果不存在, 将返回 NSNotFound
- (nullable id<SJMediaInfo>)mediaAtIndex:(NSInteger)index;

- (void)replaceMedias:(NSArray<id<SJMediaInfo>> *)medias;
- (void)addMedia:(id<SJMediaInfo>)media;
- (void)removeAllMedias;

@property SJSupportedPlaybackMode supportedMode;
@property SJPlaybackMode mode; // 播放模式
- (void)changePlaybackMode;

@property (strong, readonly, nullable) id<SJMediaInfo> currentMedia;
- (void)playPreviousMedia;
- (void)playNextMedia;
- (void)playAtIndex:(NSInteger)idx;

- (NSArray<id<SJMediaInfo>> * _Nonnull)medias;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
@end


@protocol SJMediaInfo <NSObject>
@property (nonatomic, readonly) NSInteger id;
@property (nonatomic, strong, readonly) SJVideoPlayerURLAsset *asset;
@end

@protocol SJPlaybackListControllerObserver <NSObject>
@property (nonatomic, copy, nullable) void(^prepareToPlayMediaExeBlock)(id<SJPlaybackListController> controller);
@property (nonatomic, copy, nullable) void(^playbackModeDidChangeExdBlock)(id<SJPlaybackListController> controller);
@property (nonatomic, copy, nullable) void(^listDidChangeExeBlock)(id<SJPlaybackListController> controller);
@end

extern NSNotificationName const SJPlaybackListControllerPrepareToPlayMediaNotification;
extern NSNotificationName const SJPlaybackListControllerPlaybackModeDidChangeNotification;
extern NSNotificationName const SJPlaybackListControllerListDidChangeNotification;
NS_ASSUME_NONNULL_END

#endif /* SJPlaybackListControllerProtocol_h */
