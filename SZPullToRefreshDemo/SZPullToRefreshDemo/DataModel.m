//
//  DataModel.m
//  SZPullToRefreshDemo
//
//  Created by shengzhichen on 16/5/7.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import "DataModel.h"

@implementation DataModel

+ (instancetype)modelWithTop:(CGFloat)top bottom:(CGFloat)bottom numberOfRow:(NSUInteger)numberOfRow {
    DataModel *dm = [[DataModel alloc] init];
    dm.numberOfRow = numberOfRow;
    dm.inset = UIEdgeInsetsMake(top, 0, bottom, 0);
    return dm;
}

- (NSString *)title {
    return [NSString stringWithFormat:@"top:%.0f--bottom:%.0f--row:%@", _inset.top, _inset.bottom, @(_numberOfRow)];
}

@end
