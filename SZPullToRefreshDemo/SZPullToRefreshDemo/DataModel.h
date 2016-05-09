//
//  DataModel.h
//  SZPullToRefreshDemo
//
//  Created by shengzhichen on 16/5/7.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataModel : NSObject

@property (nonatomic) UIEdgeInsets inset;

@property (nonatomic) NSUInteger numberOfRow;

+ (instancetype)modelWithTop:(CGFloat)top bottom:(CGFloat)bottom numberOfRow:(NSUInteger)numberOfRow;

- (NSString *)title;

@end
