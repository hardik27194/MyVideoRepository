//
//  VideoEditViewController.m
//  InstaShot
//
//  Created by Liu Xiang on 10/24/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import "VideoEditViewController.h"
#import "ISCommand.h"
#import "ISRotateCommand.h"

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (180.0 * x / M_PI)

enum {
    VideoEditTypeOverview = 0,
    VideoEditTypeTrim = 1,
    VideoEditTypeFit = 2,
    VideoEditTypeBackground = 3,
};
typedef UInt32 VideoEditType;

@interface VideoEditViewController ()
{
    ISVideoTrimToolbar *videoTrimToolbar;
    ISVideoFitToolbar *videoFitToolbar;
    ISColorPicker *colorPicker;
    UIPanGestureRecognizer *panGestureRecognizer;
    UITapGestureRecognizer *tapGestureRecognizer;
    AVAsset *movieAsset;
}

@property (assign, nonatomic) VideoEditType curEditType;
@property (assign, nonatomic) VideoEditType prevEditType;

@end

@implementation VideoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    CGRect titleBarBtnFrame = CGRectMake(0, 0, 32, 32);
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.frame = titleBarBtnFrame;
    [saveBtn setImage:[UIImage imageNamed:@"icon_save"] forState:UIControlStateNormal];
    
    UIButton *shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    shareBtn.frame = titleBarBtnFrame;
    [shareBtn setImage:[UIImage imageNamed:@"icon_share"] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(saveVideo:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *instagramBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    instagramBtn.frame = titleBarBtnFrame;
    [instagramBtn setImage:[UIImage imageNamed:@"icon_share_instagram"] forState:UIControlStateNormal];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:instagramBtn],[[UIBarButtonItem alloc] initWithCustomView:shareBtn],[[UIBarButtonItem alloc] initWithCustomView:saveBtn], nil];
    
    mainToolbar = [[ISMainToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height -44, self.view.bounds.size.width, 44)];
    mainToolbar.delegate = self;
    mainToolbar.backgroundColor = [UIColor clearColor];
    mainToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:mainToolbar];
    
    confirmToolbar = [[ISConfirmToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 44)];
    confirmToolbar.delegate = self;
    confirmToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:confirmToolbar];
    
    NSURL *sourceVideoURL = [ISVideoManager sharedInstance].video.videoURL;
    movieAsset   = [AVURLAsset URLAssetWithURL:sourceVideoURL options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    __weak VideoEditViewController *weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1f, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf syncScrubber];
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [playerBorderView.layer insertSublayer:self.playerLayer atIndex:0];
    [self.player play];
    
    playerActionView.frame = self.playerLayer.frame;
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(handlePan:)];
    panGestureRecognizer.delegate = self;
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(handleTap:)];
    tapGestureRecognizer.delegate = self;
    [playerActionView addGestureRecognizer:panGestureRecognizer];
    [playerActionView addGestureRecognizer:tapGestureRecognizer];
    [panGestureRecognizer setEnabled:NO];
    [playerView bringSubviewToFront:playPauseBtn];
    [playerView bringSubviewToFront:goToFirstBtn];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editCommandCompletionNotificationReceiver:)
                                                 name:ISEditCommandCompletionNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

- (void)viewDidAppear:(BOOL)animated
{
    vedioProgressView.hidden = NO;
    [vedioProgressView setFrame:CGRectMake(0, playerView.frame.origin.y+playerView.frame.size.height, vedioProgressView.frame.size.width, vedioProgressView.frame.size.height)];
}

- (void)viewWillDisappear:(BOOL)animated
{

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark--
#pragma mark-- Setter/Getter Methods
- (float)duration
{
    AVPlayerItem *playerItem = [[self player] currentItem];
    if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
        return CMTimeGetSeconds([[playerItem asset] duration]);
    else
        return 0.f;
}

- (float)currentTime
{
    return CMTimeGetSeconds([[self player] currentTime]);
}

- (void)setCurrentTime:(float)time
{
    if (time == 0.f) {
        [vedioProgressView setProgress:time/[self duration] animated:NO];
    }else{
        [vedioProgressView setProgress:time/[self duration] animated:YES];
    }
    [[self player] seekToTime:CMTimeMakeWithSeconds(time, 1)];
}

- (void)setCurEditType:(VideoEditType)curEditType
{
    _curEditType = curEditType;
    switch (curEditType) {
        case VideoEditTypeOverview:
        {
            [panGestureRecognizer setEnabled:NO];
            [self commonHideAnimation];
            break;
        }
        case VideoEditTypeTrim:
        {
            [self pause];
            confirmToolbar.title = @"Cut Video";
            if (videoTrimToolbar == nil || videoTrimToolbar.superview == nil) {
                videoTrimToolbar = [[ISVideoTrimToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 60 - confirmToolbar.frame.size.height, self.view.bounds.size.width, 60)];
                videoTrimToolbar.delegate = self;
                videoTrimToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
                [self.view addSubview:videoTrimToolbar];
            }
            videoTrimToolbar.hidden = YES;
            videoTrimToolbar.maxValue = self.duration;
            [self commonShowAnimation];
            break;
        }
        case VideoEditTypeFit:
        {
            if ([[ISVideoManager sharedInstance] videoFitType] != VideoFitTypeOriginal) [panGestureRecognizer setEnabled:YES];
            confirmToolbar.title = @"Video Position";
            if (videoFitToolbar == nil || videoFitToolbar.superview == nil) {
                videoFitToolbar = [[ISVideoFitToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 60 - confirmToolbar.frame.size.height, self.view.bounds.size.width, 60)];
                videoFitToolbar.delegate = self;
                videoFitToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
                [self.view addSubview:videoFitToolbar];
            }
            videoFitToolbar.hidden = YES;
            videoFitToolbar.fitType = [[ISVideoManager sharedInstance] videoFitType];
            videoFitToolbar.borderType = [[ISVideoManager sharedInstance] videoBorderType];
            [self commonShowAnimation];
            break;
        }
        case VideoEditTypeBackground:
        {
            confirmToolbar.title = @"Background Color";
            if (colorPicker == nil || colorPicker.superview == nil) {
                colorPicker = [[ISColorPicker alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 60 - confirmToolbar.frame.size.height, self.view.bounds.size.width, 60)];
                colorPicker.delegate = self;
                colorPicker.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
                [self.view addSubview:colorPicker];
            }
            colorPicker.hidden = YES;
            [self commonShowAnimation];
            break;
        }
        default:
            break;
    }
}

#pragma mark--
#pragma mark-- UI Update Methods
//update progress slider
- (void)syncScrubber
{
    if ([self duration] == 0) return;
    CGFloat currentSecond = (float)self.playerItem.currentTime.value/(float)self.playerItem.currentTime.timescale;
    [vedioProgressView setProgress:currentSecond/[self duration] animated:YES];
}

- (void)preview
{
    //update background
    if (self.curEditType == VideoEditTypeOverview) {
        playerView.backgroundColor = [[ISVideoManager sharedInstance] videoBgColor];
    }else{
        playerView.backgroundColor = [[ISVideoManager sharedInstance] previewBgColor];
    }
    
    //update fit type
    CGRect playerLayerFrame;
    VideoFitType fitType;
    if (self.curEditType == VideoEditTypeOverview) {
        fitType = [[ISVideoManager sharedInstance] videoFitType];
    }else{
        fitType = [[ISVideoManager sharedInstance] previewFitType];
        if (fitType == VideoFitTypeOriginal) {
            [panGestureRecognizer setEnabled:NO];
        }else{
            [panGestureRecognizer setEnabled:YES];
        }
    }
    switch (fitType) {
        case VideoFitTypeOriginal:
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            playerBorderView.frame = CGRectMake(0, 0, playerView.frame.size.width, playerView.frame.size.height);
            playerLayerFrame = CGRectMake(0, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);
            break;
        case VideoFitTypeFit:
        {
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            [self updatePlayerLayerWithBorder];
            playerLayerFrame = CGRectMake(0, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);
            break;
        }
        case VideoFitTypeFull:
        {
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            [self updatePlayerLayerWithBorder];
            playerLayerFrame = CGRectMake(0, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);
            break;
        }
        case VideoFitTypeLeft:
        {
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            [self updatePlayerLayerWithBorder];
            self.playerLayer.frame = CGRectMake(0, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);;
            CGRect rect = self.playerLayer.videoRect;
            playerLayerFrame = CGRectMake(-rect.origin.x/2, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);
            break;
        }
        case VideoFitTypeRight:
        {
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            [self updatePlayerLayerWithBorder];
            self.playerLayer.frame = CGRectMake(0, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);;
            CGRect rect = self.playerLayer.videoRect;
            playerLayerFrame = CGRectMake(rect.origin.x/2, 0, playerBorderView.frame.size.width, playerBorderView.frame.size.height);
            break;
        }
        default:
            break;
    }
    
    self.playerLayer.frame = playerLayerFrame;
    self.playerLayer.bounds = playerLayerFrame;
    [self.playerLayer removeAllAnimations];
    playerActionView.frame = self.playerLayer.frame;
}

- (void)updatePlayerLayerWithBorder
{
    VideoBorderType borderType;
    if (self.curEditType == VideoEditTypeOverview) {
        borderType = [[ISVideoManager sharedInstance] videoBorderType];
    }else{
        borderType = [[ISVideoManager sharedInstance] previewBorderType];
    }
    switch (borderType) {
        case VideoBorderTypeOriginal:
        {
            playerBorderView.frame = CGRectMake(0, 0, playerView.frame.size.width, playerView.frame.size.height);
            break;
        }
        case VideoBorderType1:
        {
            playerBorderView.frame = CGRectMake(10, 10, playerView.frame.size.width - 20, playerView.frame.size.height - 20);
            break;
        }
        case VideoBorderType2:
        {
            playerBorderView.frame = CGRectMake(20, 20, playerView.frame.size.width - 40, playerView.frame.size.height - 40);
            break;
        }
        case VideoBorderType3:
        {
            playerBorderView.frame = CGRectMake(30, 30, playerView.frame.size.width - 60, playerView.frame.size.height - 60);
            break;
        }
        default:
            break;
    }
}

#pragma mark--
#pragma mark-- AVPlayer mothods
- (void)play
{
    if (self.currentTime == self.duration)self.currentTime = 0.f;
    [self.player play];
    [playPauseBtn setHidden:YES];
    [goToFirstBtn setHidden:YES];
}

- (void)pause
{
    [[self player] pause];
    [playPauseBtn setHidden:NO];
    [goToFirstBtn setHidden:NO];
}

- (void)restart
{
    self.currentTime = 0.f;
    [self.player play];
    [playPauseBtn setHidden:YES];
    [goToFirstBtn setHidden:YES];
}

#pragma mark--
#pragma mark-- AVPlayer Notification
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [playPauseBtn setHidden:NO];
    [goToFirstBtn setHidden:NO];
}

#pragma mark--
#pragma mark-- UI Interaction Methods
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:self.view];
    
    CALayer *videolayer = self.playerLayer;
    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    [CATransaction setDisableActions:YES];
    CGRect rect = videolayer.bounds;
    rect.origin.x = recognizer.view.center.x + translation.x - rect.size.width/2;
    rect.origin.y = recognizer.view.center.y + translation.y - rect.size.height/2;
    videolayer.bounds = rect;
    [CATransaction commit];
}

- (void)handleTap:(UIPanGestureRecognizer *)recognizer
{
    if ([self.player rate] != 1.f) {
        [self play];
    } else {
        [self pause];
    }
}

- (IBAction)playPauseToggle:(id)sender
{
    if ([[self player] rate] != 1.f) {
        [self play];
    } else {
        [self pause];
    }
}

- (IBAction)goToFirstToggle:(id)sender
{
    [self restart];
}

- (void)cutAction
{
    self.prevEditType = self.curEditType;
    self.curEditType = VideoEditTypeTrim;
}

- (void)fitAction
{
    self.prevEditType = self.curEditType;
    self.curEditType = VideoEditTypeFit;
}

- (void)musicAction
{
    
}

- (void)changeBgAction
{
    self.prevEditType = self.curEditType;
    self.curEditType = VideoEditTypeBackground;
}

- (void)rotateAction
{
    ISRotateCommand *editCommand = [[ISRotateCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix];
    VideoRotateType curRotateType = [[ISVideoManager sharedInstance] videoRotateType];
    switch (curRotateType) {
        case VideoRotateTypeOriginal:
            [ISVideoManager sharedInstance].previewRotateType = VideoRotateTypeRotate90;
            [editCommand performWithAsset:movieAsset andRotate:90.0];
            break;
        case VideoRotateTypeRotate90:
            [ISVideoManager sharedInstance].previewRotateType = VideoRotateTypeRotate180;
            [editCommand performWithAsset:movieAsset andRotate:180.0];
            break;
        case VideoRotateTypeRotate180:
            [ISVideoManager sharedInstance].previewRotateType = VideoRotateTypeRotate270;
            [editCommand performWithAsset:movieAsset andRotate:-90.0];
            break;
        case VideoRotateTypeRotate270:
            [ISVideoManager sharedInstance].previewRotateType = VideoRotateTypeOriginal;
            [editCommand performWithAsset:movieAsset andRotate:0.0];
            break;
        default:
            break;
    }
    [[ISVideoManager sharedInstance] savePreviewVideo];
}

- (void)flipAction
{

}

#pragma mark--
#pragma mark-- Animation Implementation
- (void)commonShowAnimation
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:0.2f animations:^{
        mainToolbar.center = CGPointMake(mainToolbar.center.x, mainToolbar.center.y + mainToolbar.frame.size.height);
    } completion:^(BOOL finished) {
        [self showEditToolbar];
        [UIView animateWithDuration:0.2f animations:^{
            confirmToolbar.center = CGPointMake(confirmToolbar.center.x, confirmToolbar.center.y - confirmToolbar.frame.size.height);
        }];
    }];
}

- (void)commonHideAnimation
{
    [self hideEditToolbar];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.2f animations:^{
        confirmToolbar.center = CGPointMake(confirmToolbar.center.x, confirmToolbar.center.y + confirmToolbar.frame.size.height);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2f animations:^{
            mainToolbar.center = CGPointMake(mainToolbar.center.x, mainToolbar.center.y - mainToolbar.frame.size.height);
        }];
    }];
}

- (void)showEditToolbar
{
    switch (_curEditType) {
        case VideoEditTypeTrim:
        {
            videoTrimToolbar.hidden = NO;
            break;
        }
        case VideoEditTypeFit:
        {
            videoFitToolbar.hidden = NO;
            break;
        }
        case VideoEditTypeBackground:
        {
            colorPicker.hidden = NO;
            break;
        }
        default:
            break;
    }
}

- (void)hideEditToolbar
{
    switch (_prevEditType) {
        case VideoEditTypeTrim:
            if (videoTrimToolbar.superview != nil) [videoTrimToolbar removeFromSuperview];
            break;
        case VideoEditTypeFit:
            if (videoFitToolbar.superview != nil) [videoFitToolbar removeFromSuperview];
            break;
        case VideoEditTypeBackground:
            if (colorPicker.superview != nil) [colorPicker removeFromSuperview];
            break;
        default:
            break;
    }
}

#pragma mark--
#pragma mark-- ISMainToolbar Delegate
- (void)mainToolbar:(ISMainToolbar *)toolbar clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self cutAction];
            break;
        case 1:
            [self fitAction];
            break;
        case 2:
            [self musicAction];
            break;
        case 3:
            [self changeBgAction];
            break;
        case 4:
            [self rotateAction];
            break;
        case 5:
            [self flipAction];
            break;
        default:
            break;
    }
}

#pragma mark--
#pragma mark-- ISConfirmToolbar Delegate
- (void)confirmToolbar:(ISConfirmToolbar *)toolbar clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //Cacel the changes
    }else if (buttonIndex == 1){
        //Save the changes
        [[ISVideoManager sharedInstance] savePreviewVideo];
    }
    self.prevEditType = self.curEditType;
    self.curEditType = VideoEditTypeOverview;
    [self preview];
}

#pragma mark--
#pragma mark-- ISVideoTrimToolbar Delegate
- (void)videoTrimToolbar:(ISVideoTrimToolbar *)toolbar rangeSliderDidSlectedAtMinValue:(float)minValue andMaxValue:(float)maxValue
{
    
}

#pragma mark--
#pragma mark-- ISVideoFitToolbar Delegate
- (void)videoFitToolbar:(ISVideoFitToolbar *)toolbar reviewAtFitType:(VideoFitType)fitType andBorderType:(VideoBorderType)borderType
{
    [ISVideoManager sharedInstance].previewBorderType = borderType;
    [ISVideoManager sharedInstance].previewFitType = fitType;
    [self preview];
}

#pragma mark--
#pragma mark-- ISColorPicker Delegate
- (void)colorPicker:(ISColorPicker *)colorPicker selectedAtColor:(UIColor *)color
{
    [ISVideoManager sharedInstance].previewBgColor = color;
    [self preview];
}

#pragma mark--
#pragma mark-- UIGestureRecognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if([touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    return YES;
}

- (void)editCommandCompletionNotificationReceiver:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:ISEditCommandCompletionNotification]) {
        self.composition = [[notification object] mutableComposition];
        self.videoComposition = [[notification object] mutableVideoComposition];
        self.audioMix = [[notification object] mutableAudioMix];
        dispatch_async( dispatch_get_main_queue(), ^{
            self.videoComposition.animationTool = NULL;
            AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
            playerItem.videoComposition = self.videoComposition;
            playerItem.audioMix = self.audioMix;
            [[self player] replaceCurrentItemWithPlayerItem:playerItem];
        });
    }
}

- (void)saveVideo:(id)sender
{
    
}

@end
