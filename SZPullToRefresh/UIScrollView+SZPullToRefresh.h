//
//  UIScrollView+SZPullToRefresh.h
//  SZPullToRefreshDemo
//
//  Created by 陈圣治 on 16/5/7.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SZPullToRefreshPosition) {
    SZPullToRefreshPositionTop = 0,
    SZPullToRefreshPositionBottom,
};

typedef NS_ENUM(NSUInteger, SZPullToRefreshState) {
    SZPullToRefreshStateStopped = 0,
    SZPullToRefreshStateTriggered,
    SZPullToRefreshStateLoading,
};


@protocol SZPullToRefreshViewSubclassProtocol <NSObject>

- (void)startAnimatingWithDuration:(NSTimeInterval)duration;
- (void)stopAnimatingWithDuration:(NSTimeInterval)duration;
- (void)loadingAnimating;
- (void)updateTriggerProgressForDragging:(CGFloat)progress;

@end


@interface SZPullToRefreshView : UIView <SZPullToRefreshViewSubclassProtocol>

@property (nonatomic, readonly) SZPullToRefreshState state;
@property (nonatomic, readonly) SZPullToRefreshPosition position;

@property (nonatomic) BOOL enableRefresh;

+ (CGFloat)defaultRefreshViewHeight;
+ (NSTimeInterval)defaultRefreshViewAnimationDuration;

+ (void)setDefaultRefreshViewHeight:(CGFloat)refreshViewHeight;
+ (void)setDefaultRefreshViewAnimationDuration:(NSTimeInterval)refreshViewAnimationDuration;

@end


@interface UIScrollView (SZPullToRefresh) <UIScrollViewDelegate>

@property (nonatomic, strong) SZPullToRefreshView *topRefreshView;
@property (nonatomic, strong) SZPullToRefreshView *bottomRefreshView;

@property (nonatomic) UIEdgeInsets refreshViewInset;

+ (void)setDefaultPullRefreshViewClass:(Class)pullRefreshViewClass;
- (void)setCurrrentPullRefreshViewClass:(Class)pullRefreshViewClass;

- (SZPullToRefreshView *)addTopRefreshWithActionHandler:(void (^)(void))actionHandler;
- (SZPullToRefreshView *)addBottomRefreshWithActionHandler:(void (^)(void))actionHandler;

- (void)triggerTopPullToRefresh;
- (void)triggerBottomPullToRefresh;
- (void)endPullToRefresh;

@end


