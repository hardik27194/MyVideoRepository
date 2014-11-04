//
//  ISVideoTrimToolbar.m
//  InstaShot
//
//  Created by Liu Xiang on 10/28/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import "ISVideoTrimToolbar.h"

#define ISVIDEOTRIMTOOLBAR_LEFT_PADDING         30
#define ISVIDEOTRIMTOOLBAR_TIME_LABEL_WIDTH     50
#define ISVIDEOTRIMTOOLBAR_TIME_LABEL_HEIGHT    20

@implementation ISVideoTrimToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        fromTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(ISVIDEOTRIMTOOLBAR_LEFT_PADDING, 0, ISVIDEOTRIMTOOLBAR_TIME_LABEL_WIDTH, ISVIDEOTRIMTOOLBAR_TIME_LABEL_HEIGHT)];
        fromTimeLabel.backgroundColor = [UIColor clearColor];
        fromTimeLabel.textColor = [UIColor whiteColor];
        fromTimeLabel.font = [UIFont systemFontOfSize:12.0f];
        fromTimeLabel.textAlignment = NSTextAlignmentLeft;
        [self addSubview:fromTimeLabel];
        
        endTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - ISVIDEOTRIMTOOLBAR_LEFT_PADDING - ISVIDEOTRIMTOOLBAR_TIME_LABEL_WIDTH, 0, ISVIDEOTRIMTOOLBAR_TIME_LABEL_WIDTH, ISVIDEOTRIMTOOLBAR_TIME_LABEL_HEIGHT)];
        endTimeLabel.backgroundColor = [UIColor clearColor];
        endTimeLabel.textColor = [UIColor whiteColor];
        endTimeLabel.font = [UIFont systemFontOfSize:12.0f];
        endTimeLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:endTimeLabel];
        
        totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(fromTimeLabel.frame.origin.x + fromTimeLabel.frame.size.width, 0, frame.size.width - fromTimeLabel.frame.size.width - endTimeLabel.frame.size.width - ISVIDEOTRIMTOOLBAR_LEFT_PADDING*2, ISVIDEOTRIMTOOLBAR_TIME_LABEL_HEIGHT)];
        totalTimeLabel.backgroundColor = [UIColor clearColor];
        totalTimeLabel.textColor = [UIColor redColor];
        totalTimeLabel.font = [UIFont systemFontOfSize:12.0f];
        totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:totalTimeLabel];
        
        rangePickSlider = [[NMRangeSlider alloc] initWithFrame:CGRectMake(ISVIDEOTRIMTOOLBAR_LEFT_PADDING, ISVIDEOTRIMTOOLBAR_TIME_LABEL_HEIGHT, frame.size.width - ISVIDEOTRIMTOOLBAR_LEFT_PADDING*2, frame.size.height - ISVIDEOTRIMTOOLBAR_TIME_LABEL_HEIGHT)];
        
        UIImage* image = nil;
        
        image = [UIImage imageNamed:@"slider-metal-trackBackground"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0)];
        rangePickSlider.trackBackgroundImage = image;
        
        image = [UIImage imageNamed:@"slide_volume"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 2.0)];
        rangePickSlider.trackImage = image;
        
        image = [UIImage imageNamed:@"btn_trimleft"];
        rangePickSlider.lowerHandleImageNormal = image;
        rangePickSlider.lowerHandleImageHighlighted = image;
        
        image = [UIImage imageNamed:@"btn_trimright"];
        rangePickSlider.upperHandleImageNormal = image;
        rangePickSlider.upperHandleImageHighlighted = image;
        
        rangePickSlider.lowerValue = 0.0;
        rangePickSlider.upperValue = 1.0;
        [self addSubview:rangePickSlider];
    }
    return self;
}

- (void)setMaxValue:(float)maxValue
{
    totalTimeLabel.text = [NSString stringWithFormat:@"TOTAL: %@",[ISHelper timeFormatter:(int)maxValue]];
}

@end
