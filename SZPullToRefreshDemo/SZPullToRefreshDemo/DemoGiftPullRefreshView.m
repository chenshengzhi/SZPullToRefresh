//
//  DemoGiftPullRefreshView.m
//  SZPullToRefreshDemo
//
//  Created by 陈圣治 on 2016/10/14.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import "DemoGiftPullRefreshView.h"

@implementation DemoGiftPullRefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImage *image = [UIImage animatedImageNamed:@"加载动画_" duration:1];
        _imageView = [[UIImageView alloc] initWithImage:image.images[0]];
        _imageView.animationImages = image.images;
        _imageView.animationDuration = 1;
        [self addSubview:_imageView];
        [_imageView stopAnimating];

        _imageView.alpha = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect frame = _imageView.frame;
    frame.origin.x = ceil(self.frame.size.width/2 - frame.size.width/2);
    frame.origin.y = ceil(self.frame.size.height/2 - frame.size.height/2);
    _imageView.frame = frame;
}

#pragma mark - SZPullToRefreshViewSubclassProtocol -

- (void)refreshViewOpenAnimatingWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        _imageView.alpha = 1;
    } completion:nil];
}

- (void)refreshViewLoadingAnimating {
    [_imageView startAnimating];
}

- (void)refreshViewLloadingEnd {
    [_imageView stopAnimating];
}

- (void)refreshViewCloseAnimatingWithDuration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        _imageView.alpha = 0;
    } completion:nil];
}

- (void)refreshViewUpdateTriggerProgressForDragging:(CGFloat)progress {
    if (progress >= 1.0) {
        [_imageView startAnimating];
    } else {
        [_imageView stopAnimating];
    }

    _imageView.alpha = MIN(1, progress);
}

@end
