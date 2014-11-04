//
//  VideoEditViewController.h
//  InstaShot
//
//  Created by Liu Xiang on 10/24/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ISConfirmToolbar.h"
#import "ISMainToolbar.h"
#import "ISVideoTrimToolbar.h"
#import "ISVideoFitToolbar.h"
#import "ISColorPicker.h"

@interface VideoEditViewController : UIViewController<UIGestureRecognizerDelegate,ISConfirmToolbarDelegate,ISMainToolbarDelegate,ISVideoTrimToolbarDelegate,ISVideoFitToolbarDelegate,ISColorPickerDelegate>
{
    ISMainToolbar *mainToolbar;
    ISConfirmToolbar *confirmToolbar;
    IBOutlet UIView *playerView;
    IBOutlet UIView *playerBorderView;
    IBOutlet UIView *playerActionView;
    IBOutlet UIButton *playPauseBtn;
    IBOutlet UIButton *goToFirstBtn;
    IBOutlet UIProgressView *vedioProgressView;
}

@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (assign, nonatomic) float currentTime;
@property (assign, nonatomic,readonly) float duration;

@property AVMutableComposition *composition;
@property AVMutableVideoComposition *videoComposition;
@property AVMutableAudioMix *audioMix;

@end
