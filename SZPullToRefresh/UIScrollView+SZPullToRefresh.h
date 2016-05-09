//
//  UIScrollView+SZPullToRefresh.h
//  SZPullToRefreshDemo
//
//  Created by 陈圣治 on 16/5/7.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>


@class SZPullToRefreshView;

typedef NS_ENUM(NSUInteger, SZPullToRefreshPosition) {
    SZPullToRefreshPositionTop = 0,
    SZPullToRefreshPositionBottom,
};

@interface UIScrollView (SZPullToRefresh) <UIScrollViewDelegate>

@property (nonatomic, strong) SZPullToRefreshView *topRefreshView;
@property (nonatomic, strong) SZPullToRefreshView *bottomRefreshView;

- (SZPullToRefreshView *)addTopRefreshWithActionHandler:(void (^)(void))actionHandler;
- (SZPullToRefreshView *)addBottomRefreshWithActionHandler:(void (^)(void))actionHandler;

- (void)addExternalTopInset:(CGFloat)externalTopInset;

- (void)triggerTopPullToRefresh;
- (void)triggerBottomPullToRefresh;
- (void)endPullToRefresh;

@end


typedef NS_ENUM(NSUInteger, SZPullToRefreshState) {
    SZPullToRefreshStateStopped = 0,
    SZPullToRefreshStateTriggered,
    SZPullToRefreshStateLoading,
};

@interface SZPullToRefreshView : UIView

@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, readonly) SZPullToRefreshState state;
@property (nonatomic, readonly) SZPullToRefreshPosition position;

@property (nonatomic) BOOL enableRefresh;

@end
