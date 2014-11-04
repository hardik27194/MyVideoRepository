//
//  ISVideoManager.m
//  InstaShot
//
//  Created by Liu Xiang on 10/30/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import "ISVideoManager.h"

@interface ISVideoManager ()

@end

@implementation ISVideoManager

+ (ISVideoManager *)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (ISVideoManager *)init
{
    if (self = [super init]) {
        
    }
    return self;
}

- (void)setVideo:(ISVideo *)video
{
    _video = video;
    self.previewBgColor = video.bgColor;
    self.previewFitType = video.fitType;
    self.previewBorderType = video.borderType;
    self.previewRotateType = video.rotateType;
    self.previewFlipType = video.flipType;
}

- (VideoFitType)videoFitType
{
    return self.video.fitType;
}

- (VideoBorderType)videoBorderType
{
    return self.video.borderType;
}

- (VideoRotateType)videoRotateType
{
    return self.video.rotateType;
}

- (VideoFlipType)videoFlipType
{
    return self.video.flipType;
}

- (UIColor *)videoBgColor
{
    return self.video.bgColor;
}

- (void)reset
{
    self.video.fitType = VideoFitTypeOriginal;
    self.video.borderType = VideoBorderTypeOriginal;
    self.video.rotateType = VideoRotateTypeOriginal;
    self.video.flipType = VideoFlipTypeOriginal;
    self.video.bgColor = [UIColor whiteColor];
}

- (void)savePreviewVideo
{
    self.video.fitType = self.previewFitType;
    self.video.borderType = self.previewBorderType;
    self.video.rotateType = self.previewRotateType;
    self.video.flipType = self.previewFlipType;
    self.video.bgColor = self.previewBgColor;
}

@end
