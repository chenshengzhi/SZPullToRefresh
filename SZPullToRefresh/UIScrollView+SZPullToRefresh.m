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
static CGFloat SZDefaultPullToRefershAnimationDuration = 0.3;
static Class SZDefaultPullRefreshViewClass;

@interface SZPullToRefreshView ()

@property (nonatomic, copy) void (^pullToRefreshActionHandler)(void);

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@property (nonatomic, readwrite) SZPullToRefreshState state;
@property (nonatomic, readwrite) SZPullToRefreshPosition position;

@property (nonatomic, weak) UIScrollView *scrollView;

@property(nonatomic, assign) BOOL isObserving;

@property (nonatomic) BOOL insetForSelfAppended;

@property (nonatomic) CGFloat originBottomInset;


- (void)layoutSelf;

- (void)triggerPullToRefresh;
- (void)endPullToRefresh;

@end



#pragma mark - UIScrollView (SZPullToRefresh) -

static char SZScrollViewTopRefreshViewKey;
static char SZScrollViewBottomRefreshViewKey;
static char SZScrollViewRefreshViewInsetKey;

@implementation UIScrollView (SZPullToRefresh)

+ (void)setDefaultPullRefreshViewClass:(Class)pullRefreshViewClass {
    NSAssert([pullRefreshViewClass isSubclassOfClass:SZPullToRefreshView.class], @"pullRefreshViewClass should be subclass of SZPullToRefreshView");
    SZDefaultPullRefreshViewClass = pullRefreshViewClass;
}

- (SZPullToRefreshView *)addPullToRefreshWithActionHandler:(void (^)(void))actionHandler position:(SZPullToRefreshPosition)position {
    CGFloat yOrigin = 0;
    
    if (position == SZPullToRefreshPositionTop) {
        if (self.topRefreshView) {
            return self.topRefreshView;
        } else {
            yOrigin = -SZDefaultPullToRefreshViewHeight - self.contentInset.top;
        }
    } else if (position == SZPullToRefreshPositionBottom) {
        if (self.bottomRefreshView) {
            return self.bottomRefreshView;
        } else {
            yOrigin = MAX(self.contentSize.height + self.contentInset.bottom, self.bounds.size.height);
        }
    } else {
        return nil;
    }

    Class class = SZDefaultPullRefreshViewClass;
    if (!class) {
        class = [SZNormalPullToRefreshView class];
    }
    SZPullToRefreshView *view = [[class alloc] initWithFrame:CGRectMake(0, yOrigin, self.bounds.size.width, SZDefaultPullToRefreshViewHeight)];
    view.pullToRefreshActionHandler = actionHandler;
    view.scrollView = self;
    [self addSubview:view];
    
    view.position = position;
    view.enableRefresh = YES;
    
    if (position == SZPullToRefreshPositionTop) {
        self.topRefreshView = view;
    } else {
        self.bottomRefreshView = view;
    }
    
    [view layoutSelf];
    
    return view;
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

+ (CGFloat)defaultRefreshViewHeight {
    return SZDefaultPullToRefreshViewHeight;
}

+ (NSTimeInterval)defaultRefreshViewAnimationDuration {
    return SZDefaultPullToRefershAnimationDuration;
}

+ (void)setDefaultRefreshViewHeight:(CGFloat)refreshViewHeight {
    SZDefaultPullToRefreshViewHeight = refreshViewHeight;
}

+ (void)setDefaultRefreshViewAnimationDuration:(NSTimeInterval)refreshViewAnimationDuration{
    SZDefaultPullToRefershAnimationDuration = refreshViewAnimationDuration;
}

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tintColor = [UIColor grayColor];
        
        self.activityIndicatorView.color = self.tintColor;
        self.state = SZPullToRefreshStateStopped;
        
        CGRect activityIndicatorFrame = self.activityIndicatorView.frame;
        activityIndicatorFrame.origin.x = self.frame.size.width/2 - activityIndicatorFrame.size.width/2;
        activityIndicatorFrame.origin.y = self.frame.size.height/2 - activityIndicatorFrame.size.height/2;
        self.activityIndicatorView.frame = activityIndicatorFrame;
        
        [self progressLayer];
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
            currentInsets.top -= SZDefaultPullToRefreshViewHeight;
            break;
        case SZPullToRefreshPositionBottom:
            currentInsets.bottom = self.originBottomInset;
            break;
    }
    [self animateScrollViewContentInset:currentInsets];
}

- (void)setScrollViewContentInsetForLoading {
    if (_insetForSelfAppended) {
        return;
    }
    _insetForSelfAppended = YES;
    
    UIEdgeInsets currentInsets = self.scrollView.contentInset;
    switch (self.position) {
        case SZPullToRefreshPositionTop:
            currentInsets.top += SZDefaultPullToRefreshViewHeight;
            break;
        case SZPullToRefreshPositionBottom:
            self.originBottomInset = self.scrollView.contentInset.bottom;
            currentInsets.bottom += SZDefaultPullToRefreshViewHeight - MIN(0, self.scrollView.contentSize.height + currentInsets.top + currentInsets.bottom - self.scrollView.bounds.size.height);
            break;
    }
    [self animateScrollViewContentInset:currentInsets];
}

- (void)animateScrollViewContentInset:(UIEdgeInsets)contentInset {
    [UIView animateWithDuration:SZDefaultPullToRefershAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.scrollView.contentInset = contentInset;
                     }
                     completion:NULL];
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
                                     - (_insetForSelfAppended ? 0 : SZDefaultPullToRefreshViewHeight));
            break;
        case SZPullToRefreshPositionBottom: {
            UIEdgeInsets scrollViewInsets = self.scrollView.contentInset;
            if (self.scrollView.topRefreshView && self.scrollView.topRefreshView.insetForSelfAppended) {
                scrollViewInsets.top -= SZDefaultPullToRefreshViewHeight;
            }
            if (_insetForSelfAppended) {
                scrollViewInsets.bottom -= SZDefaultPullToRefreshViewHeight;
            }
            if (self.scrollView.contentSize.height + scrollViewInsets.top + scrollViewInsets.bottom < self.scrollView.bounds.size.height) {
                scrollOffsetThreshold = 0 - scrollViewInsets.top + SZDefaultPullToRefreshViewHeight;
            } else {
                scrollOffsetThreshold = (self.scrollView.contentSize.height
                                         + scrollViewInsets.bottom
                                         + SZDefaultPullToRefreshViewHeight
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
                if (contentOffsetY <= scrollOffsetThreshold + SZDefaultPullToRefreshViewHeight
                    && self.state != SZPullToRefreshStateLoading) {
                    CGFloat yOffset = contentOffsetY - (scrollOffsetThreshold + SZDefaultPullToRefreshViewHeight);
                    [self updateTriggerProgressForDragging:-yOffset/SZDefaultPullToRefreshViewHeight];
                }
                break;
            }
            case SZPullToRefreshPositionBottom: {
                if (contentOffsetY >= scrollOffsetThreshold - SZDefaultPullToRefreshViewHeight
                    && self.state != SZPullToRefreshStateLoading) {
                    CGFloat yOffset = contentOffsetY - (scrollOffsetThreshold - SZDefaultPullToRefreshViewHeight);
                    [self updateTriggerProgressForDragging:yOffset/SZDefaultPullToRefreshViewHeight];
                }
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - Getters -

- (UIActivityIndicatorView *)activityIndicatorView {
    if(!_activityIndicatorView) {
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:_activityIndicatorView];
    }
    return _activityIndicatorView;
}

- (CAShapeLayer *)progressLayer {
    if (!_progressLayer) {
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
    return _progressLayer;
}

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
            [self resetScrollViewContentInset];
            if (!self.scrollView.dragging && !self.scrollView.decelerating) {
                [self stopAnimatingWithDuration:SZDefaultPullToRefershAnimationDuration];
            }
            break;
        }
        case SZPullToRefreshStateTriggered:
            if (!self.scrollView.dragging && !self.scrollView.decelerating) {
                [self startAnimatingWithDuration:SZDefaultPullToRefershAnimationDuration];
            }
            break;
            
        case SZPullToRefreshStateLoading: {
            [self setScrollViewContentInsetForLoading];
            
            if(previousState == SZPullToRefreshStateTriggered && self.pullToRefreshActionHandler) {
                self.pullToRefreshActionHandler();
            }
            break;
        }
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    _activityIndicatorView.color = tintColor;
    _progressLayer.strokeColor = tintColor.CGColor;
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
            yOrigin = -SZDefaultPullToRefreshViewHeight - self.scrollView.contentInset.top + self.scrollView.refreshViewInset.top;
            if (_insetForSelfAppended) {
                yOrigin += SZDefaultPullToRefreshViewHeight;
            }
            break;
        }
        case SZPullToRefreshPositionBottom: {
            UIEdgeInsets scrollViewInsets = self.scrollView.contentInset;
            if (self.scrollView.topRefreshView && self.scrollView.topRefreshView.insetForSelfAppended) {
                scrollViewInsets.top -= SZDefaultPullToRefreshViewHeight;
            }
            if (_insetForSelfAppended) {
                scrollViewInsets.bottom -= SZDefaultPullToRefreshViewHeight;
            }
            if (self.scrollView.contentSize.height + scrollViewInsets.top + scrollViewInsets.bottom < self.scrollView.bounds.size.height) {
                yOrigin = self.scrollView.bounds.size.height - scrollViewInsets.top - self.scrollView.refreshViewInset.bottom;
            } else {
                yOrigin = self.scrollView.contentSize.height + scrollViewInsets.bottom - self.scrollView.refreshViewInset.bottom;
            }
            break;
        }
    }
    
    self.frame = CGRectMake(0, yOrigin, self.bounds.size.width, SZDefaultPullToRefreshViewHeight);
    SZPullToRefreshLog(@"%@", NSStringFromCGRect(self.frame));
}

#pragma mark - SZPullToRefreshViewSubclassProtocol -

- (void)startAnimatingWithDuration:(NSTimeInterval)duration {
    NSAssert(NO, @"subclass should override this method for animation");
}

- (void)stopAnimatingWithDuration:(NSTimeInterval)duration {
    NSAssert(NO, @"subclass should override this method for animation");
}

- (void)updateTriggerProgressForDragging:(CGFloat)progress {
    NSAssert(NO, @"subclass should override this method for animation");
}

@end
