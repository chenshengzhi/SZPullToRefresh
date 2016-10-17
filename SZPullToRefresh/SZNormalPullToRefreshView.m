//
//  SZNormalPullToRefreshView.m
//  SZPullToRefreshDemo
//
//  Created by 陈圣治 on 2016/10/14.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import "SZNormalPullToRefreshView.h"
#import <QuartzCore/QuartzCore.h>

@interface SZNormalPullToRefreshView () <CAAnimationDelegate>

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation SZNormalPullToRefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _activityIndicatorView.hidesWhenStopped = YES;
        [self addSubview:_activityIndicatorView];

        _progressLayer = [CAShapeLayer layer];
        CGFloat length = 26;
        _progressLayer.frame = CGRectMake(0, 0, length, length);
        UIBezierPath *bezier = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, length, length) cornerRadius:length/2];
        _progressLayer.path = bezier.CGPath;
        _progressLayer.strokeColor = self.tintColor.CGColor;
        _progressLayer.fillColor = [UIColor clearColor].CGColor;
        _progressLayer.lineCap = kCALineJoinRound;
        _progressLayer.lineJoin = kCALineJoinRound;
        _progressLayer.strokeStart = 0;
        _progressLayer.strokeEnd = 0;
        _progressLayer.lineWidth = 4;
        _progressLayer.actions = @{@"strokeEnd": [NSNull null]};
        [self.layer addSublayer:_progressLayer];
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];

    _activityIndicatorView.color = tintColor;
    _progressLayer.strokeColor = tintColor.CGColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect activityIndicatorFrame = self.activityIndicatorView.frame;
    activityIndicatorFrame.origin.x = self.frame.size.width/2 - activityIndicatorFrame.size.width/2;
    activityIndicatorFrame.origin.y = self.frame.size.height/2 - activityIndicatorFrame.size.height/2;
    self.activityIndicatorView.frame = activityIndicatorFrame;

    CGRect layerFrame = self.progressLayer.frame;
    layerFrame.origin.x = self.frame.size.width/2 - layerFrame.size.width/2;
    layerFrame.origin.y = self.frame.size.height/2 - layerFrame.size.height/2;
    self.progressLayer.frame = layerFrame;
}

#pragma mark - SZPullToRefreshViewSubclassProtocol -
- (void)refreshViewOpenAnimatingWithDuration:(NSTimeInterval)duration {
    self.progressLayer.hidden = NO;
    self.progressLayer.strokeEnd = 1;
    CABasicAnimation *startAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    startAnimation.fromValue = @0;
    startAnimation.toValue = @1;
    startAnimation.duration = duration;
    [self.progressLayer addAnimation:startAnimation forKey:nil];

    [self.activityIndicatorView stopAnimating];
}

- (void)refreshViewLoadingAnimating {
    self.progressLayer.hidden = YES;
    [self.activityIndicatorView startAnimating];
}

- (void)refreshViewLloadingEnd {
    [self.activityIndicatorView stopAnimating];
}

- (void)refreshViewCloseAnimatingWithDuration:(NSTimeInterval)duration {
    self.progressLayer.hidden = NO;
    self.progressLayer.strokeEnd = 0;

    CABasicAnimation *stopAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    stopAnimation.fromValue = @1;
    stopAnimation.toValue = @0;
    stopAnimation.duration = duration;
    [self.progressLayer addAnimation:stopAnimation forKey:nil];
}

- (void)refreshViewUpdateTriggerProgressForDragging:(CGFloat)progress {
    progress = MIN(progress, 1);
    self.progressLayer.strokeEnd = progress;

    if (self.state != SZPullToRefreshStateLoading) {
        if (progress >= 1) {
            [self.activityIndicatorView startAnimating];
            self.progressLayer.hidden = YES;
        } else {
            [self.activityIndicatorView stopAnimating];
            self.progressLayer.hidden = NO;
        }
    }
}

@end
