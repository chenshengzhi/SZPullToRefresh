//
//  UIScrollView+SZPullToRefresh.m
//  SZPullToRefreshDemo
//
//  Created by 陈圣治 on 16/5/7.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import "UIScrollView+SZPullToRefresh.h"
#import "SZNormalPullToRefreshView.h"
#import <objc/runtime.h>

//#define DebugSZPullToRefresh

#ifdef DebugSZPullToRefresh
#define SZPullToRefreshLog(fmt, ...) NSLog((@" %d %s " fmt), __LINE__, __PRETTY_FUNCTION__,  ##__VA_ARGS__)
#else
#define SZPullToRefreshLog(fmt, ...) do{}while(0)
#endif

static CGFloat SZDefaultPullToRefreshViewHeight = 80;
static CGFloat SZDefaultPullToRefreshAnimationDuration = 0.3;
static Class SZDefaultPullRefreshViewClass;

@interface SZPullToRefreshView ()

@property (nonatomic) BOOL respondsToCurrentRefreshViewHeight;
@property (nonatomic) BOOL respondsToCurrentRefreshViewAnimationDuration;

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, readwrite) SZPullToRefreshState state;
@property (nonatomic, readwrite) SZPullToRefreshPosition position;

@property (nonatomic, weak) UIScrollView *scrollView;

@property(nonatomic, assign) BOOL isObserving;

@property (nonatomic) BOOL insetForSelfAppended;

@property (nonatomic) CGFloat originBottomInset;


- (void)layoutSelf;

- (void)triggerPullToRefresh;
- (void)endPullToRefresh;

- (CGFloat)refreshViewHeight;
- (NSTimeInterval)refreshViewAnimationDuration;

@end



#pragma mark - UIScrollView (SZPullToRefresh) -

static char SZScrollViewTopRefreshViewKey;
static char SZScrollViewBottomRefreshViewKey;
static char SZScrollViewRefreshViewInsetKey;
static char SZScrollViewCurrentPullRefreshViewClassKey;

@implementation UIScrollView (SZPullToRefresh)

+ (void)setDefaultPullRefreshViewClass:(Class)pullRefreshViewClass {
    NSAssert([pullRefreshViewClass isSubclassOfClass:SZPullToRefreshView.class], @"pullRefreshViewClass should be subclass of SZPullToRefreshView");
    SZDefaultPullRefreshViewClass = pullRefreshViewClass;
}

- (void)setCurrrentPullRefreshViewClass:(Class)pullRefreshViewClass {
    NSAssert([pullRefreshViewClass isSubclassOfClass:SZPullToRefreshView.class], @"pullRefreshViewClass should be subclass of SZPullToRefreshView");
    objc_setAssociatedObject(self,
                             &SZScrollViewCurrentPullRefreshViewClassKey,
                             pullRefreshViewClass,
                             OBJC_ASSOCIATION_RETAIN);
}

+ (void)setDefaultRefreshViewHeight:(CGFloat)refreshViewHeight {
    SZDefaultPullToRefreshViewHeight = refreshViewHeight;
}

+ (void)setDefaultRefreshViewAnimationDuration:(NSTimeInterval)refreshViewAnimationDuration{
    SZDefaultPullToRefreshAnimationDuration = refreshViewAnimationDuration;
}

- (Class)currrentPullRefreshViewClass {
    return objc_getAssociatedObject(self, &SZScrollViewCurrentPullRefreshViewClassKey);
}

- (SZPullToRefreshView *)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(SZPullToRefreshPosition)position {
    Class class = [self currrentPullRefreshViewClass];
    if (!class) {
        class = SZDefaultPullRefreshViewClass;
    }
    if (!class) {
        class = [SZNormalPullToRefreshView class];
    }
    SZPullToRefreshView *refreshView = [[class alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, SZDefaultPullToRefreshViewHeight)];
    refreshView.pullToRefreshActionHandler = actionHandler;
    refreshView.scrollView = self;

    CGRect refreshViewFrame = refreshView.frame;
    refreshViewFrame.size.height = [refreshView refreshViewHeight];

    if (position == SZPullToRefreshPositionTop) {
        if (self.topRefreshView) {
            return self.topRefreshView;
        } else {
            refreshViewFrame.origin.y = -refreshViewFrame.size.height - self.contentInset.top;
        }
    } else if (position == SZPullToRefreshPositionBottom) {
        if (self.bottomRefreshView) {
            return self.bottomRefreshView;
        } else {
            refreshViewFrame.origin.y = MAX(self.contentSize.height + self.contentInset.bottom, self.bounds.size.height);
        }
    } else {
        return nil;
    }
    refreshView.frame = refreshViewFrame;

    [self addSubview:refreshView];

    refreshView.position = position;
    refreshView.enableRefresh = YES;
    
    if (position == SZPullToRefreshPositionTop) {
        self.topRefreshView = refreshView;
    } else {
        self.bottomRefreshView = refreshView;
    }
    
    [refreshView layoutSelf];
    
    return refreshView;
}

- (SZPullToRefreshView *)addTopRefreshWithActionHandler:(void (^)(void))actionHandler {
    return [self addPullToRefreshWithActionHandler:actionHandler position:SZPullToRefreshPositionTop];
}

- (SZPullToRefreshView *)addBottomRefreshWithActionHandler:(void (^)(void))actionHandler {
    return [self addPullToRefreshWithActionHandler:actionHandler position:SZPullToRefreshPositionBottom];
}

- (void)triggerTopPullToRefresh {
    [self.topRefreshView triggerPullToRefresh];
}

- (void)triggerBottomPullToRefresh {
    [self.bottomRefreshView triggerPullToRefresh];
}

- (void)endPullToRefresh {
    [self.topRefreshView endPullToRefresh];
    [self.bottomRefreshView endPullToRefresh];
}

- (void)setTopRefreshView:(SZPullToRefreshView *)topRefreshView {
    [self willChangeValueForKey:@"topRefreshView"];
    objc_setAssociatedObject(self,
                             &SZScrollViewTopRefreshViewKey,
                             topRefreshView,
                             OBJC_ASSOCIATION_RETAIN);
    [self didChangeValueForKey:@"topRefreshView"];
}

- (SZPullToRefreshView *)topRefreshView {
    return objc_getAssociatedObject(self, &SZScrollViewTopRefreshViewKey);
}


- (void)setBottomRefreshView:(SZPullToRefreshView *)bottomRefreshView {
    [self willChangeValueForKey:@"bottomRefreshView"];
    objc_setAssociatedObject(self,
                             &SZScrollViewBottomRefreshViewKey,
                             bottomRefreshView,
                             OBJC_ASSOCIATION_RETAIN);
    [self didChangeValueForKey:@"bottomRefreshView"];
}

- (SZPullToRefreshView *)bottomRefreshView {
    return objc_getAssociatedObject(self, &SZScrollViewBottomRefreshViewKey);
}

- (void)setRefreshViewInset:(UIEdgeInsets)refreshViewInset {
    [self willChangeValueForKey:@"refreshViewInset"];
    objc_setAssociatedObject(self,
                             &SZScrollViewRefreshViewInsetKey,
                             [NSValue valueWithUIEdgeInsets:refreshViewInset],
                             OBJC_ASSOCIATION_RETAIN);
    [self didChangeValueForKey:@"refreshViewInset"];

    if (self.topRefreshView) {
        [self.topRefreshView layoutSelf];
    }
    if (self.bottomRefreshView) {
        [self.bottomRefreshView layoutSelf];
    }
}

- (UIEdgeInsets)refreshViewInset {
    return [objc_getAssociatedObject(self, &SZScrollViewRefreshViewInsetKey) UIEdgeInsetsValue];
}

@end

#pragma mark - SZPullToRefresh -
@implementation SZPullToRefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.respondsToCurrentRefreshViewHeight = [self respondsToSelector:@selector(currentRefreshViewHeight)];
        self.respondsToCurrentRefreshViewAnimationDuration = [self respondsToSelector:@selector(currentRefreshViewAnimationDuration)];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        //use self.superview, not self.scrollView. Why self.scrollView == nil here?
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (self.position == SZPullToRefreshPositionTop) {
            if (scrollView.topRefreshView) {
                [self removeObserversIfNeededWithScrollView:scrollView];
            }
        } else {
            if (scrollView.bottomRefreshView) {
                [self removeObserversIfNeededWithScrollView:scrollView];
            }
        }
    }
}

- (void)dealloc {
    SZPullToRefreshLog(@"%@, position: %@", self.description, @(self.position));
}

#pragma mark - Scroll View -

- (void)resetScrollViewContentInset {
    if (!_insetForSelfAppended) {
        return;
    }
    _insetForSelfAppended = NO;
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case SZPullToRefreshPositionTop:
            currentInsets.top -= [self refreshViewHeight];
            break;
        case SZPullToRefreshPositionBottom:
            currentInsets.bottom = self.originBottomInset;
            break;
    }
    [self animateScrollViewContentInset:currentInsets completion:nil];
}

- (void)setScrollViewContentInsetForLoadingWithCompletion:(dispatch_block_t)completion {
    if (_insetForSelfAppended) {
        return;
    }
    _insetForSelfAppended = YES;
    
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case SZPullToRefreshPositionTop:
            currentInsets.top += [self refreshViewHeight];
            break;
        case SZPullToRefreshPositionBottom:
            self.originBottomInset = self.scrollView.contentInset.bottom;
            currentInsets.bottom += [self refreshViewHeight] - MIN(0, self.scrollView.contentSize.height + currentInsets.top + currentInsets.bottom - self.scrollView.bounds.size.height);
            break;
    }
    [self animateScrollViewContentInset:currentInsets completion:completion];
}

- (void)animateScrollViewContentInset:(UIEdgeInsets)contentInset completion:(dispatch_block_t)completion {
    [UIView animateWithDuration:[self refreshViewAnimationDuration]
                          delay:0
                        options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:^(BOOL finished) {
                         if (completion) {
                             completion();
                         }
                     }];
}

#pragma mark - Observing -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"]) {
        SZPullToRefreshLog(@"+++ contentOffset = %@", [change valueForKey:NSKeyValueChangeNewKey]);
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue].y];
    } else if([keyPath isEqualToString:@"contentSize"]) {
        
        [self layoutSelf];
    } else if ([keyPath isEqualToString:@"contentInset"]) {
        SZPullToRefreshLog(@"*** contentInset = %@", [change valueForKey:NSKeyValueChangeNewKey]);
        [self layoutSelf];
    }
}

- (void)scrollViewDidScroll:(CGFloat)contentOffsetY {
    CGFloat scrollOffsetThreshold = 0;
    switch (self.position) {
        case SZPullToRefreshPositionTop:
            scrollOffsetThreshold = (0
                                     - self.scrollView.contentInset.top
                                     - (_insetForSelfAppended ? 0 : [self refreshViewHeight]));
            break;
        case SZPullToRefreshPositionBottom: {
            UIEdgeInsets scrollViewInsets = self.scrollView.contentInset;
            if (self.scrollView.topRefreshView && self.scrollView.topRefreshView.insetForSelfAppended) {
                scrollViewInsets.top -= [self refreshViewHeight];
            }
            if (_insetForSelfAppended) {
                scrollViewInsets.bottom -= [self refreshViewHeight];
            }
            if (self.scrollView.contentSize.height + scrollViewInsets.top + scrollViewInsets.bottom < self.scrollView.bounds.size.height) {
                scrollOffsetThreshold = 0 - scrollViewInsets.top + [self refreshViewHeight];
            } else {
                scrollOffsetThreshold = (self.scrollView.contentSize.height
                                         + scrollViewInsets.bottom
                                         + [self refreshViewHeight]
                                         - self.scrollView.bounds.size.height);
            }
            SZPullToRefreshLog(@"%f", scrollOffsetThreshold);
            break;
        }
        default:
            break;
    }

    if (self.state != SZPullToRefreshStateLoading) {
        if (!self.scrollView.isDragging
            && self.state == SZPullToRefreshStateTriggered) {
            self.state = SZPullToRefreshStateLoading;
        } else if (contentOffsetY < scrollOffsetThreshold
                   && self.scrollView.isDragging
                   && self.state == SZPullToRefreshStateStopped
                   && self.position == SZPullToRefreshPositionTop) {
            self.state = SZPullToRefreshStateTriggered;
        } else if (contentOffsetY >= scrollOffsetThreshold
                   && self.state != SZPullToRefreshStateStopped
                   && self.position == SZPullToRefreshPositionTop) {
            self.state = SZPullToRefreshStateStopped;
        } else if (contentOffsetY > scrollOffsetThreshold
                   && self.scrollView.isDragging
                   && self.state == SZPullToRefreshStateStopped
                   && self.position == SZPullToRefreshPositionBottom) {
            self.state = SZPullToRefreshStateTriggered;
        } else if (contentOffsetY <= scrollOffsetThreshold
                   && self.state != SZPullToRefreshStateStopped
                   && self.position == SZPullToRefreshPositionBottom) {
            self.state = SZPullToRefreshStateStopped;
        }
    }
    
    if (self.scrollView.isDragging || self.scrollView.isDecelerating) {
        switch (self.position) {
            case SZPullToRefreshPositionTop: {
                if (contentOffsetY <= scrollOffsetThreshold + [self refreshViewHeight]
                    && self.state != SZPullToRefreshStateLoading) {
                    CGFloat yOffset = contentOffsetY - (scrollOffsetThreshold + [self refreshViewHeight]);
                    [self refreshViewUpdateTriggerProgressForDragging:-yOffset/[self refreshViewHeight]];
                }
                break;
            }
            case SZPullToRefreshPositionBottom: {
                if (contentOffsetY >= scrollOffsetThreshold - [self refreshViewHeight]
                    && self.state != SZPullToRefreshStateLoading) {
                    CGFloat yOffset = contentOffsetY - (scrollOffsetThreshold - [self refreshViewHeight]);
                    [self refreshViewUpdateTriggerProgressForDragging:yOffset/[self refreshViewHeight]];
                }
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Getters -

- (BOOL)enableRefresh {
    return !self.hidden;
}

#pragma mark - Setters -

- (void)setEnableRefresh:(BOOL)enableRefresh {
    self.hidden = !enableRefresh;
    
    if(!enableRefresh) {
        if (self.isObserving) {
            [self removeObserversIfNeededWithScrollView:self.scrollView];
            [self resetScrollViewContentInset];
        }
    }
    else {
        [self addObserversIfNeeded];
    }
}

- (void)setState:(SZPullToRefreshState)newState {
    if(_state == newState) {
        return;
    }
    
    SZPullToRefreshState previousState = _state;
    _state = newState;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    switch (newState) {
        case SZPullToRefreshStateStopped: {
            [self refreshViewLloadingEnd];
            [self resetScrollViewContentInset];
            if (!self.scrollView.dragging && !self.scrollView.decelerating) {
                [self refreshViewCloseAnimatingWithDuration:[self refreshViewAnimationDuration]];
            }
            break;
        }
        case SZPullToRefreshStateTriggered:
            if (!self.scrollView.dragging && !self.scrollView.decelerating) {
                [self refreshViewOpenAnimatingWithDuration:[self refreshViewAnimationDuration]];
            }
            break;
            
        case SZPullToRefreshStateLoading: {
            __weak typeof(self) weakSelf = self;
            [self setScrollViewContentInsetForLoadingWithCompletion:^{
                if (weakSelf.state == SZPullToRefreshStateLoading) {
                    [weakSelf refreshViewLoadingAnimating];
                }
            }];

            if(previousState == SZPullToRefreshStateTriggered && self.pullToRefreshActionHandler) {
                self.pullToRefreshActionHandler();
            }
            break;
        }
    }
}

#pragma mark - Add/Remove Observers -

- (void)removeObserversIfNeededWithScrollView:(UIScrollView *)scrollView {
    if (self.isObserving) {
        [scrollView removeObserver:self forKeyPath:@"contentOffset"];
        [scrollView removeObserver:self forKeyPath:@"contentSize"];
        [scrollView removeObserver:self forKeyPath:@"contentInset"];
        self.isObserving = NO;
    }
}

- (void)addObserversIfNeeded {
    if (!self.isObserving) {
        [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        [self.scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        [self.scrollView addObserver:self forKeyPath:@"contentInset" options:NSKeyValueObservingOptionNew context:nil];
        self.isObserving = YES;
    }
}

#pragma mark - Start/End Refresh -
- (void)triggerPullToRefresh {
    self.state = SZPullToRefreshStateTriggered;
    self.state = SZPullToRefreshStateLoading;
}

- (void)endPullToRefresh {
    self.state = SZPullToRefreshStateStopped;
}

#pragma mark - layout -

- (void)layoutSelf {
    CGFloat yOrigin = 0;
    switch (self.position) {
        case SZPullToRefreshPositionTop: {
            yOrigin = -[self refreshViewHeight] - self.scrollView.contentInset.top + self.scrollView.refreshViewInset.top;
            if (_insetForSelfAppended) {
                yOrigin += [self refreshViewHeight];
            }
            break;
        }
        case SZPullToRefreshPositionBottom: {
            UIEdgeInsets scrollViewInsets = self.scrollView.contentInset;
            if (self.scrollView.topRefreshView && self.scrollView.topRefreshView.insetForSelfAppended) {
                scrollViewInsets.top -= [self refreshViewHeight];
            }
            if (_insetForSelfAppended) {
                scrollViewInsets.bottom -= [self refreshViewHeight];
            }
            if (self.scrollView.contentSize.height + scrollViewInsets.top + scrollViewInsets.bottom < self.scrollView.bounds.size.height) {
                yOrigin = self.scrollView.bounds.size.height - scrollViewInsets.top - self.scrollView.refreshViewInset.bottom;
            } else {
                yOrigin = self.scrollView.contentSize.height + scrollViewInsets.bottom - self.scrollView.refreshViewInset.bottom;
            }
            break;
        }
    }
    
    self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, [self refreshViewHeight]);
    SZPullToRefreshLog(@"%@", NSStringFromCGRect(self.frame));
}

#pragma mark - Others -
- (CGFloat)refreshViewHeight {
    if (self.respondsToCurrentRefreshViewHeight) {
        return [self currentRefreshViewHeight];
    } else {
        return SZDefaultPullToRefreshViewHeight;
    }
}

- (NSTimeInterval)refreshViewAnimationDuration {
    if (self.respondsToCurrentRefreshViewAnimationDuration) {
        return [self currentRefreshViewAnimationDuration];
    } else {
        return SZDefaultPullToRefreshAnimationDuration;
    }
}

#pragma mark - SZPullToRefreshViewSubclassProtocol -

- (void)refreshViewOpenAnimatingWithDuration:(NSTimeInterval)duration {
    NSAssert(NO, @"subclass should override this method for animation");
}

- (void)refreshViewLoadingAnimating {
    NSAssert(NO, @"subclass should override this method for animation");
}

- (void)refreshViewLloadingEnd {
    NSAssert(NO, @"subclass should override this method for animation");
}

- (void)refreshViewCloseAnimatingWithDuration:(NSTimeInterval)duration {
    NSAssert(NO, @"subclass should override this method for animation");
}

- (void)refreshViewUpdateTriggerProgressForDragging:(CGFloat)progress {
    NSAssert(NO, @"subclass should override this method for animation");
}

@end
