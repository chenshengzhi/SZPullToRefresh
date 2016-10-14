//
//  DetailTableViewController.m
//  SZPullToRefreshDemo
//
//  Created by shengzhichen on 16/5/7.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import "DetailTableViewController.h"
#import "UIScrollView+SZPullToRefresh.h"
#import "SZNormalPullToRefreshView.h"

@interface DetailTableViewController ()

@end

@implementation DetailTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (arc4random_uniform(2) == 0) {
        [self.tableView setCurrrentPullRefreshViewClass:[SZNormalPullToRefreshView class]];
    }

    self.tableView.rowHeight = 60;
    
    self.tableView.contentInset = _inset;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    [self.navigationController setNavigationBarHidden:!_showNavigationBar animated:YES];
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addTopRefreshWithActionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.tableView endPullToRefresh];
        });
    }];
    
    [self.tableView addBottomRefreshWithActionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.tableView endPullToRefresh];
        });
    }];

    self.tableView.refreshViewInset = UIEdgeInsetsMake((_showNavigationBar?64:[UIApplication sharedApplication].statusBarFrame.size.height),
                                                  0,
                                                  80,
                                                  0);

    self.tableView.topRefreshView.tintColor = [UIColor colorWithRed:(arc4random()%255)/255.0 green:(arc4random()%255)/255.0 blue:(arc4random()%255)/255.0 alpha:1];
    self.tableView.bottomRefreshView.tintColor = [UIColor colorWithRed:(arc4random()%255)/255.0 green:(arc4random()%255)/255.0 blue:(arc4random()%255)/255.0 alpha:1];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView triggerTopPullToRefresh];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _numberOfRow;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
