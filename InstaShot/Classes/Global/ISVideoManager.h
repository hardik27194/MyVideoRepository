//
//  ISVideoManager.h
//  InstaShot
//
//  Created by Liu Xiang on 10/30/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISVideo.h"

@interface ISVideoManager : NSObject

@property (strong, nonatomic) ISVideo *video;
@property (strong, nonatomic) UIColor *previewBgColor;
@property (assign, nonatomic) VideoFitType previewFitType;
@property (assign, nonatomic) VideoBorderType previewBorderType;
@property (assign, nonatomic) VideoRotateType previewRotateType;
@property (assign, nonatomic) VideoFlipType previewFlipType;

+ (ISVideoManager *)sharedInstance;

- (VideoFitType)videoFitType;
- (VideoBorderType)videoBorderType;
- (VideoRotateType)videoRotateType;
- (VideoFlipType)videoFlipType;
- (UIColor *)videoBgColor;

- (void)reset;
- (void)savePreviewVideo;

@end
