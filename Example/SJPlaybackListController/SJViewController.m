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

@protocol TestVideoPlayerDelegate <NSObject>
- (void)playbackDidFinish:(TestVideoPlayer *)player;
@end

#pragma mark -

@interface TestVideoItem : NSObject<SJPlaybackItem>
+ (instancetype)testVideo;
- (instancetype)initWithId:(NSInteger)id url:(NSString *)url;
@property (nonatomic) NSInteger id;
@property (nonatomic, strong) NSString *url;
@end

@implementation TestVideoItem
+ (instancetype)testVideo {
    static NSInteger idx = 0;
    NSInteger videoId = ++idx;
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
@end

#pragma mark -

@interface TestVideoPlayer : NSObject<SJPlaybackController>
@property (nonatomic, copy, nullable) SJPlaybackCompletionHandler playbackCompletionHandler;
@property (nonatomic, readonly) BOOL isPaused;

@property (nonatomic, strong, readonly, nullable) TestVideoItem *curItem;
- (void)playWithItem:(TestVideoItem *)item;
- (void)replay;
- (void)stop;
@end

@implementation TestVideoPlayer
- (void)playWithItem:(TestVideoItem *)item {
    NSLog(@"%s video.id = %ld;", sel_getName(_cmd), (long)item.id);
    
    _curItem = item;
    [self _delay];
}

- (void)replay {
    NSLog(@"%s", sel_getName(_cmd));

    [self _delay];
}

- (void)stop {
    NSLog(@"%s", sel_getName(_cmd));

    _curItem = nil;
    _isPaused = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)_delay {
    _isPaused = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(_playbackDidComplete) withObject:nil afterDelay:5];
}

- (void)_playbackDidComplete {
    NSLog(@"%s", sel_getName(_cmd));

    if ( _playbackCompletionHandler ) _playbackCompletionHandler();
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
    _listController = [SJPlaybackListController.alloc initWithPlaybackController:_player];
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
