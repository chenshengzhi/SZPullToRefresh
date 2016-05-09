//
//  ListViewController.m
//  SZPullToRefreshDemo
//
//  Created by 陈圣治 on 16/5/7.
//  Copyright © 2016年 shengzhichen. All rights reserved.
//

#import "ListViewController.h"
#import "DataModel.h"
#import "DetailTableViewController.h"

@interface ListViewController ()

@property (nonatomic, strong) NSArray *datasource;

@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.rowHeight = 60;
    
    _datasource = @[
                    [DataModel modelWithTop:0 bottom:0 numberOfRow:1],
                    [DataModel modelWithTop:300 bottom:0 numberOfRow:1],
                    [DataModel modelWithTop:600 bottom:0 numberOfRow:1],
                    [DataModel modelWithTop:900 bottom:0 numberOfRow:1],
                    [DataModel modelWithTop:0 bottom:300 numberOfRow:1],
                    [DataModel modelWithTop:0 bottom:600 numberOfRow:1],
                    [DataModel modelWithTop:0 bottom:900 numberOfRow:1],
                    [DataModel modelWithTop:300 bottom:300 numberOfRow:1],
                    [DataModel modelWithTop:600 bottom:600 numberOfRow:1],
                    [DataModel modelWithTop:900 bottom:900 numberOfRow:1],
                    [DataModel modelWithTop:0 bottom:0 numberOfRow:10],
                    [DataModel modelWithTop:300 bottom:0 numberOfRow:10],
                    [DataModel modelWithTop:600 bottom:0 numberOfRow:10],
                    [DataModel modelWithTop:900 bottom:0 numberOfRow:10],
                    [DataModel modelWithTop:0 bottom:300 numberOfRow:10],
                    [DataModel modelWithTop:0 bottom:600 numberOfRow:10],
                    [DataModel modelWithTop:0 bottom:900 numberOfRow:10],
                    [DataModel modelWithTop:300 bottom:300 numberOfRow:10],
                    [DataModel modelWithTop:600 bottom:600 numberOfRow:10],
                    [DataModel modelWithTop:900 bottom:900 numberOfRow:10],
                    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - UITableViewDataSource/UITableViewDelegate -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    if (indexPath.row < _datasource.count) {
        DataModel *model = _datasource[indexPath.row];
        cell.textLabel.text = model.title;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < _datasource.count) {
        DataModel *model = _datasource[indexPath.row];
        
        DetailTableViewController *vc = [[DetailTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        vc.inset = model.inset;
        vc.numberOfRow = model.numberOfRow;
        vc.showNavigationBar = indexPath.section == 0;
        vc.title = model.title;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
