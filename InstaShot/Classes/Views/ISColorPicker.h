//
//  ISColorPicker.h
//  InstaShot
//
//  Created by Liu Xiang on 10/28/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISScrollView.h"

@protocol ISColorPickerDelegate;

@interface ISColorPicker : UIView
{
    ISScrollView *scrollView;
    NSMutableArray *colorArr;
}

@property (nonatomic, unsafe_unretained) id<ISColorPickerDelegate> delegate;

@end

@protocol ISColorPickerDelegate <NSObject>
@optional
- (void)colorPicker:(ISColorPicker *)colorPicker selectedAtColor:(UIColor *)color;
@end
