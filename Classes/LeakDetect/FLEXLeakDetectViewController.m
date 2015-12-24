//
//  FLEXLeakDetectViewController.m
//  FLEX
//
//  Created by viczxwang on 15/12/16.
//  Copyright © 2015年 Flipboard. All rights reserved.
//

#import "FLEXLeakDetectViewController.h"
#import "FLEXLeakDetect.h"
#import "FLEXLeakOneAnalyzerResult.h"
#import "FLEXInstancesTableViewController.h"
#import "FLEXLeakDetectSettingsTableViewController.h"

@interface FLEXLeakDetectViewController () <UITableViewDelegate, UITableViewDataSource, FLEXLeakAnalyzerDelegate,
    UISearchBarDelegate>
@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) FLEXLeakDetect *leakdetect;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) NSArray *filteredSource;
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation FLEXLeakDetectViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _leakdetect = [FLEXLeakDetect sharedInstance];
        _leakdetect.analyzer.analyzerDelegate = self;
    }
    return self;
}

- (void)dealloc
{
    _leakdetect.analyzer.analyzerDelegate = nil;
    self.tableview.dataSource = nil;
    self.tableview.delegate = nil;
    self.searchBar.delegate = nil;
}

- (void)viewDidLoad
{
    // self.tableview =
    self.tableview = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableview.dataSource = self;
    self.tableview.delegate = self;
    [self.view addSubview:self.tableview];
    //[self.leakdetect enableDetect:YES];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.placeholder = @"Filter";
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.tableview.tableHeaderView = self.searchBar;

    self.title = @"📡  detect";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(settingsButtonTapped:)];
}

- (void)settingsButtonTapped:(id)sender
{
    FLEXLeakDetectSettingsTableViewController *settingsViewController =
        [[FLEXLeakDetectSettingsTableViewController alloc] init];
    settingsViewController.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(settingsViewControllerDoneTapped:)];
    settingsViewController.title = @"Leak Detect Settings";
    UINavigationController *wrapperNavigationController =
        [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    [self presentViewController:wrapperNavigationController animated:YES completion:nil];
}

- (void)settingsViewControllerDoneTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -public

- (void)configDataSource:(NSArray *)dataSource
{
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        if ([dataSource count]) {
            [self.tableview reloadData];
        }

        if (![self.searchBar.text length]) {
            _filteredSource = _dataSource;
        }
    }
}

#pragma - mark FLEXLeakAnalyzerDelegate

- (void)oneAnalyzerDidFinish:(FLEXLeakAnalyzerResultDataSource *)resultDataSource
{
    if ([[resultDataSource.analyzerResultArray lastObject] isKindOfClass:[FLEXLeakOneAnalyzerResult class]]) {
        FLEXLeakOneAnalyzerResult *oneAnalyzerResult = [resultDataSource.analyzerResultArray lastObject];
        [self configDataSource:[oneAnalyzerResult needNoticeObjectArray]];
    }
}

#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_filteredSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"leakDetecCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    if (_filteredSource[indexPath.row]) {
        if ([_filteredSource[indexPath.row] isKindOfClass:[FLEXLeakDetectObjectModel class]]) {
            FLEXLeakDetectObjectModel *object = (FLEXLeakDetectObjectModel *)_filteredSource[indexPath.row];
            [cell.textLabel setFont:[UIFont systemFontOfSize:10]];
            cell.textLabel.numberOfLines = 0;
            [cell.textLabel setText:[object description]];
        }
    }

    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_filteredSource[indexPath.row]) {
        if ([_filteredSource[indexPath.row] isKindOfClass:[FLEXLeakDetectObjectModel class]]) {
            FLEXLeakDetectObjectModel *object = (FLEXLeakDetectObjectModel *)_filteredSource[indexPath.row];

            FLEXInstancesTableViewController *instancesViewController =
                [FLEXInstancesTableViewController instancesTableViewControllerForClassName:object.className];
            [self.navigationController pushViewController:instancesViewController animated:YES];
        }
    }
}

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0) {
        NSPredicate *searchPreidcate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", searchText];
        self.filteredSource = [self.dataSource
            filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject,
                                                                            NSDictionary *bindings) {

                    if ([evaluatedObject isKindOfClass:[FLEXLeakDetectObjectModel class]]) {
                        FLEXLeakDetectObjectModel *object = (FLEXLeakDetectObjectModel *)evaluatedObject;
                        return [searchPreidcate evaluateWithObject:object.className];
                    } else {
                        return NO;
                    }
            }]];

    } else {
        self.filteredSource = self.dataSource;
    }
    [self.tableview reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}
@end
