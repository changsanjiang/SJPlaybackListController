//
//  SJViewController.m
//  SJPlaybackListController
//
//  Created by changsanjiang@gmail.com on 01/23/2019.
//  Copyright (c) 2019 changsanjiang@gmail.com. All rights reserved.
//

#import "SJViewController.h"
#import <SJPlaybackListController/SJPlaybackListController.h>
@class TestVideoPlayer;

@interface TestVideoItem : NSObject<SJPlaybackItem>
+ (instancetype)testVideo;
- (instancetype)initWithId:(NSInteger)id url:(NSString *)url;
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) NSString *url;
@end

@implementation TestVideoItem
+ (instancetype)testVideo {
    static NSInteger idx = 0;
    NSInteger videoId = idx ++;
    NSString *url = @"http://...test/video.mp4";
    return [[self alloc] initWithId:videoId url:url];
}

- (instancetype)initWithId:(NSInteger)id url:(NSString *)url {
    self = [super init];
    if ( self ) {
        _url = url;
        _id = id;
    }
    return self;
}

- (id)itemKey {
    return @(_id);
}

- (BOOL)isEqualToPlaybackItem:(TestVideoItem *)item {
    return self.id == item.id;
}
@end

#pragma mark -

@interface TestVideoPlayer : NSObject<SJPlaybackController>
@property (nonatomic, readonly) BOOL isPaused;

@property (nonatomic, strong, readonly, nullable) TestVideoItem *currentItem;
- (void)playWithItem:(TestVideoItem *)item;
- (void)replay;
- (void)stop;

- (void)registerObserver:(id<SJPlaybackControllerObserver>)observer;
- (void)removeObserver:(id<SJPlaybackControllerObserver>)observer;
@end

@implementation TestVideoPlayer {
    NSHashTable<id<SJPlaybackControllerObserver>> *_observers;
}
- (void)playWithItem:(TestVideoItem *)item {
    NSLog(@"%s video.id = %ld;", sel_getName(_cmd), (long)item.id);
    
    _currentItem = item;
    [self _delay];
}

- (void)replay {
    NSLog(@"%s", sel_getName(_cmd));

    [self _delay];
}

- (void)stop {
    NSLog(@"%s", sel_getName(_cmd));

    _currentItem = nil;
    _isPaused = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)registerObserver:(id<SJPlaybackControllerObserver>)observer {
    if ( _observers == nil ) {
        _observers = NSHashTable.weakObjectsHashTable;
    }
    [_observers addObject:observer];
}

- (void)removeObserver:(id<SJPlaybackControllerObserver>)observer {
    [_observers removeObject:observer];
}

- (void)_delay {
    _isPaused = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_playbackDidComplete) withObject:nil afterDelay:5];
}

- (void)_playbackDidComplete {
    NSLog(@"%s", sel_getName(_cmd));

    if ( _observers.count != 0 ) {
        for ( id<SJPlaybackControllerObserver> observer in _observers ) {
            if ( [observer respondsToSelector:@selector(playbackControllerDidFinishPlaying:)] ) {
                [observer playbackControllerDidFinishPlaying:self];
            }
        }
    }
}
@end

#pragma mark -

@interface SJViewController ()<SJPlaybackListControllerObserver>
@property (weak, nonatomic) IBOutlet UILabel *modeLabel;
@property (nonatomic, strong) SJPlaybackListController<TestVideoItem *> *listController;
@property (nonatomic, strong) TestVideoPlayer *player;
@end

@implementation SJViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _player = TestVideoPlayer.alloc.init;
    _listController = [SJPlaybackListController.alloc initWithPlaybackController:_player queue:dispatch_get_main_queue()];
    [_listController registerObserver:self];
    
    [self _refreshModeLabel];
    
	// Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - SJPlaybackListControllerObserver

- (void)playbackListController:(id<SJPlaybackListController>)controller modeDidChange:(SJPlaybackMode)mode {
    [self _refreshModeLabel];
}

- (void)_refreshModeLabel {
    switch ( _listController.mode ) {
        case SJPlaybackModeInOrder:
            _modeLabel.text = @"播放模式: 顺序播放";
            break;
        case SJPlaybackModeRepeatOne:
            _modeLabel.text = @"播放模式: 单曲循环";
            break;
        case SJPlaybackModeShuffle:
            _modeLabel.text = @"播放模式: 随机播放";
            break;
    }
}


#pragma mark -

- (IBAction)addItem:(id)sender {
    NSLog(@"%s", sel_getName(_cmd));

    [_listController addItem:TestVideoItem.testVideo];
}

- (IBAction)addItemsFromArray:(id)sender {
    NSLog(@"%s", sel_getName(_cmd));
    
    [_listController addItemsFromArray:@[TestVideoItem.testVideo, TestVideoItem.testVideo, TestVideoItem.testVideo, TestVideoItem.testVideo, TestVideoItem.testVideo]];
}

- (IBAction)playNextItem:(id)sender {
    NSLog(@"%s", sel_getName(_cmd));
    
    [_listController playNextItem];
}

- (IBAction)playPreviousItem:(id)sender {
    NSLog(@"%s", sel_getName(_cmd));
    
    [_listController playNextItem];
}

- (IBAction)switchMode:(id)sender {
    NSLog(@"%s", sel_getName(_cmd));
    
    [_listController switchMode];
}

@end
