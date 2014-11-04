//
//  ISVideoFitToolbar.h
//  InstaShot
//
//  Created by Liu Xiang on 10/28/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISVideo.h"

@protocol ISVideoFitToolbarDelegate;

@interface ISVideoFitToolbar : UIView
{
    UIButton *borderBtn;
    UILabel *borderLabel;
}

@property (assign, nonatomic) VideoFitType fitType;
@property (assign, nonatomic) VideoBorderType borderType;
@property (nonatomic, unsafe_unretained) id<ISVideoFitToolbarDelegate> delegate;

@end

@protocol ISVideoFitToolbarDelegate <NSObject>
@optional
- (void)videoFitToolbar:(ISVideoFitToolbar *)toolbar reviewAtFitType:(VideoFitType)fitType andBorderType:(VideoBorderType)borderType;
@end
