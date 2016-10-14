//
//  SZNormalPullToRefreshView.h
//  SZPullToRefreshDemo
//
//  Created by 陈圣治 on 2016/10/14.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import "UIScrollView+SZPullToRefresh.h"

@interface SZNormalPullToRefreshView : SZPullToRefreshView

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end
