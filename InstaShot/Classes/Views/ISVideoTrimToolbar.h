//
//  ISVideoTrimToolbar.h
//  InstaShot
//
//  Created by Liu Xiang on 10/28/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NMRangeSlider.h"

@protocol ISVideoTrimToolbarDelegate;

@interface ISVideoTrimToolbar : UIView
{
    float fromTime;
    float endTime;
    UILabel *totalTimeLabel;
    UILabel *fromTimeLabel;
    UILabel *endTimeLabel;
    NMRangeSlider *rangePickSlider;
}

@property (nonatomic, assign) float maxValue;
@property (nonatomic, unsafe_unretained) id<ISVideoTrimToolbarDelegate> delegate;

@end

@protocol ISVideoTrimToolbarDelegate <NSObject>
@optional
- (void)videoTrimToolbar:(ISVideoTrimToolbar *)toolbar rangeSliderDidSlectedAtMinValue:(float)minValue andMaxValue:(float)maxValue;
@end
