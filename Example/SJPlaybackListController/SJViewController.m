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

@interface TestVideoItem : NSObject
@property (nonatomic, strong) NSString *url;
@end

@implementation TestVideoItem

@end

#pragma mark -

@interface TestVideoPlayer : NSObject
@property (nonatomic, weak, nullable) id<TestVideoPlayerDelegate> delegate;
- (void)playVideo:(TestVideoItem *)video;
- (void)replay;
@end

@implementation TestVideoPlayer
- (void)playVideo:(TestVideoItem *)video {
    [self _delay];
}

- (void)replay {
    [self _delay];
}

- (void)_delay {
    [NSObject cancelPreviousPerformRequestsWithTarget:_delegate];
    [(id)_delegate performSelector:@selector(playbackDidFinish:) withObject:self afterDelay:5];
}
@end

#pragma mark -

@interface SJViewController ()<SJPlaybackListControllerDelegate, TestVideoPlayerDelegate, SJPlaybackListControllerObserver>
@property (weak, nonatomic) IBOutlet UILabel *modeLabel;
@property (nonatomic, strong) SJPlaybackListController<TestVideoItem *> *listController;
@property (nonatomic, strong) TestVideoPlayer *player;
@end

@implementation SJViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _listController = SJPlaybackListController.alloc.init;
    _listController.delegate = self;
    _listController.infiniteListLoop = YES;
    [_listController registerObserver:self];
    
    _player = TestVideoPlayer.alloc.init;
    _player.delegate = self;
    
    [self _refreshModeLabel];
    
	// Do any additional setup after loading the view, typically from a nib.
}

#pragma mark - SJPlaybackListControllerDelegate

- (void)playbackListController:(id<SJPlaybackListController>)controller needPlayItemAtIndex:(NSInteger)index {
    NSLog(@"%s - %ld", sel_getName(_cmd), (long)index);
    
    [_player playVideo:[controller itemAtIndex:index]];
}

- (void)playbackListControllerNeedReplayCurrentItem:(id<SJPlaybackListController>)controller {
    NSLog(@"%s", sel_getName(_cmd));
    
    [_player replay];
}

#pragma mark - TestVideoPlayerDelegate
 
- (void)playbackDidFinish:(TestVideoPlayer *)player {
    NSLog(@"%s", sel_getName(_cmd));
    
    [_listController finishPlayback];
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

    [_listController addItem:TestVideoItem.new];
}

- (IBAction)addItemsFromArray:(id)sender {
    NSLog(@"%s", sel_getName(_cmd));
    
    [_listController addItemsFromArray:@[TestVideoItem.new, TestVideoItem.new, TestVideoItem.new, TestVideoItem.new, TestVideoItem.new]];
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
