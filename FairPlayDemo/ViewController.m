//
//  ViewController.m
//  FairPlayDemo
//
//  Created by NguyenVanSao on 8/15/20.
//  Copyright © 2020 NguyenVanSao. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ViewController.h"
#import "APLPlayerView.h"
#import <SigmaMultiDRM/SigmaMultiDRM.h>


NSString * const kPlayableKey        = @"playable";
NSString * const kStatusKey         = @"status";

NSString * const kRateKey            = @"rate";
NSString * const kCurrentItemKey    = @"currentItem";

static void *AVARLDelegateDemoViewControllerRateObservationContext = &AVARLDelegateDemoViewControllerRateObservationContext;
static void *AVARLDelegateDemoViewControllerStatusObservationContext = &AVARLDelegateDemoViewControllerStatusObservationContext;
static void *AVARLDelegateDemoViewControllerCurrentItemObservationContext = &AVARLDelegateDemoViewControllerCurrentItemObservationContext;


@interface ViewController ()
{
    BOOL seekToZeroBeforePlay;
    SigmaMultiDRM *sdk;
}

@property (retain, nonatomic) IBOutlet APLPlayerView *playView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *seekButton;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, copy) NSURL* URL;
@property (readwrite, retain, setter=setPlayer:, getter=player) AVPlayer* player;
@property (retain) AVPlayerItem* playerItem;

- (IBAction) issuePause:(id)sender;
- (IBAction) issuePlay:(id)sender;
- (IBAction)issueSeek:(id)sender;
- (void) setupToolbar;
- (void) initializeView;
- (void) viewDidLoad;
- (void) setURL:(NSURL *)URL;
@end

/*!
 *  Interface for the play control buttons.
 *  Play
 *  Pause
 */
@interface ViewController (PlayControl)
- (void) showButton:(id) button;
- (void) showPauseButton;
- (void) showPlayButton;
- (void) syncPlayPauseButtons;
- (void) enablePlayerButtons;
- (void) disablePlayerButtons;
@end

/*!
 *  Interface for the AVPlayer
 *  - observe the properties
 *  - initialize the play
 *  - play status
 *  - play failed
 *  - play ended
 */
@interface ViewController (PlayAsset)
- (void) observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void) prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
- (BOOL) isPlaying;
- (void) assetFailedToPrepareForPlayback:(NSError *)error;
- (void) playerItemDidReachEnd:(NSNotification *)notification;
@end

#pragma mark - ViewController

@implementation ViewController

@synthesize player, playerItem, playView, toolbar, playButton, pauseButton;

- (void) setupToolbar
{
    self.toolbar.items = [NSArray arrayWithObjects:self.playButton, self.seekButton,  nil];
    [self syncPlayPauseButtons];
}

- (void) initializeView
{
    NSURL *URL = [self setupSigma];
    if (URL)
    {
        [self setURL:URL];
    }
}
-(NSURL *)setupSigma
{
    sdk = [[SigmaMultiDRM alloc] init];
    [sdk setUserId:@"2283762"];
    [sdk setSessionId:@"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIxLTIyODM3NjIiLCJzZXNzaW9uSWQiOiJhYmMiLCJpYXQiOjE1ODQ5NDgwMjB9.tb1FFjvqGvq6XyTE3BptmotlLW51mk8mIuoGAnBUbkU"];
    NSURL *URL = [NSURL URLWithString:@"http://123.30.235.196:5635/live_staging/vtv1.stream/master.m3u8"];
    return URL;
}

- (void) viewDidLoad
{
    [self setupToolbar];
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self initializeView];
    [super viewDidAppear: animated];
}
- (void) setURL:(NSURL*)URL
{
    if ([self URL] != URL)
    {
        self->_URL = [URL copy];
        AVURLAsset *asset = [sdk assetWithUrl:URL.absoluteString];
        NSArray *requestedKeys = [NSArray arrayWithObjects:kPlayableKey, nil];
        [self prepareToPlayAsset:asset withKeys:requestedKeys];
    }
    
}
- (IBAction) issuePlay:(id)sender {
    if (YES == seekToZeroBeforePlay)
    {
        seekToZeroBeforePlay = NO;
        [self.player seekToTime:kCMTimeZero];
    }
    
    [self.player play];
    [self showPauseButton ];
}

- (IBAction)issueSeek:(id)sender {
    CMTime currentTime = self.player.currentTime;
    NSLog(@"Current Time: %f", CMTimeGetSeconds(currentTime));
    CMTime nextTime = CMTimeMakeWithSeconds(CMTimeGetSeconds(currentTime) + 240, currentTime.timescale);
    [self.player seekToTime:nextTime];
}
- (IBAction) issuePause:(id)sender {
    [self.player pause];
    [self showPlayButton];
}
@end

#pragma mark - APLViewController PlayControl

@implementation ViewController (PlayControl)

- (void) showButton:(id)button
{
    NSMutableArray *toolbarItems = [NSMutableArray arrayWithArray:[self.toolbar items]];
    [toolbarItems replaceObjectAtIndex:0 withObject:button];
    self.toolbar.items = toolbarItems;
}

- (void) showPlayButton
{
    [self showButton:self.playButton];
}

- (void) showPauseButton
{
    [self showButton:self.pauseButton];
}

- (void) syncPlayPauseButtons
{
    //If we are playing, show the pause button otherwise show the play button
    if ([self isPlaying])
    {
        [self showPauseButton];
    } else
    {
        [self showPlayButton];
    }
}

-(void) enablePlayerButtons
{
    self.playButton.enabled = YES;
    self.pauseButton.enabled = YES;
}

-(void) disablePlayerButtons
{
    self.playButton.enabled = NO;
    self.pauseButton.enabled = NO;
}

@end

#pragma mark - ViewController PlayAsset

@implementation ViewController (PlayAsset)
- (void) observeValueForKeyPath:(NSString*) path ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if (context == AVARLDelegateDemoViewControllerStatusObservationContext)
    {
        [self syncPlayPauseButtons];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerStatusUnknown:
            {
                [self disablePlayerButtons];
            }
            break;
                
            case AVPlayerStatusReadyToPlay:
            {
                [self enablePlayerButtons];
                [self.player play];
            }
            break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *pItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:pItem.error];
            }
            break;
        }
    }
    else if (context == AVARLDelegateDemoViewControllerRateObservationContext)
    {
        [self syncPlayPauseButtons];
    }
    else if (context == AVARLDelegateDemoViewControllerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
        }
        else
        {
            [self.playView setPlayer:self.player];
            [self.playView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            [self syncPlayPauseButtons];
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }

}

- (void) prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
    }
    
    if (!asset.playable)
    {
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The contents of the resource at the specified URL are not playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:0 userInfo:errorDict];
        
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    if (self.playerItem)
    {
        [self.playerItem removeObserver:self forKeyPath:kStatusKey];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    self.playerItem.preferredForwardBufferDuration = 1.0;
    [self.playerItem addObserver:self
                       forKeyPath:kStatusKey
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:AVARLDelegateDemoViewControllerStatusObservationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    seekToZeroBeforePlay = NO;
    
    if (!self.player)
    {
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        [self.player addObserver:self
                      forKeyPath:kCurrentItemKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVARLDelegateDemoViewControllerCurrentItemObservationContext];
        [self.player addObserver:self
                      forKeyPath:kRateKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVARLDelegateDemoViewControllerRateObservationContext];
    }
    
    if (self.player.currentItem != self.playerItem)
    {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
}

- (BOOL) isPlaying
{
    return [self.player rate] != 0.f;
}
-(void) assetFailedToPrepareForPlayback:(NSError *)error
{
    [self disablePlayerButtons];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}
- (void) playerItemDidReachEnd:(NSNotification *)notification
{
    seekToZeroBeforePlay = YES;
}
@end
