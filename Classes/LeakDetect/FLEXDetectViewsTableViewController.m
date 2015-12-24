//
//  FLEXDetectViewsTableViewController.m
//  UICatalog
//
//  Created by viczxwang on 15/12/20.
//  Copyright © 2015年 f. All rights reserved.
//

#import "FLEXDetectViewsTableViewController.h"
#import "FLEXHeapEnumerator.h"
#import <objc/runtime.h>
#import "FLEXUtility.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXDetectViewsTableViewController ()
@property(nonatomic, strong) NSArray *instances;
@end

@implementation FLEXDetectViewsTableViewController

- (void)viewDidLoad {
    self.title = @"Detect views";
    [super viewDidLoad];

    NSMutableArray *instances = [NSMutableArray array];
    [FLEXHeapEnumerator
            enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
                if (object) {
                    NSString *className = NSStringFromClass(actualClass);
                    if ([className isEqualToString:@"UIView"] || [self p_checkShouldDetectWithClass:actualClass]) {
                        if (![className hasPrefix:@"_"]) {

                            [instances addObject:object];
                        }
                    }
                }
            }];

    [instances enumerateObjectsUsingBlock:^(NSObject *object, NSUInteger idx, BOOL *stop) {
        if (![object isKindOfClass:[UIView class]]) {
            [instances removeObject:object];
        } else {
            // UIView* v = (UIView*)object;
            NSLog(@"%@", NSStringFromClass(object_getClass(object)));
            // TODO  这里本来是想通过frame 的大小来排序，但是每次访问 v.frame 都crash 暂未找到解决方法
        }
    }];

    self.instances = instances;
}

- (BOOL)p_checkShouldDetectWithClass:(Class)oneclass {
    if (class_getSuperclass(oneclass) && class_getSuperclass(oneclass) != [NSObject class]) {
        if (class_getSuperclass(oneclass) == [UIView class]) {
            return YES;
        } else {
            return [self p_checkShouldDetectWithClass:class_getSuperclass(oneclass)];
        }
    }
    return NO;
}

#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.instances count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        UIFont *cellFont = [FLEXUtility defaultTableViewCellLabelFont];
        cell.textLabel.font = cellFont;
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.font = cellFont;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }

    id instance = nil;
    if (indexPath.row < [self.instances count]) {
        instance = [self.instances objectAtIndex:indexPath.row];
    }

    if (instance) {
        NSString *title = nil;
        UIView *originView = nil;

        if ([instance isKindOfClass:[UIView class]]) {
            originView = (UIView *)instance;
        }
        title = [NSString stringWithFormat:@"%@ %p", NSStringFromClass(object_getClass(instance)), instance];
        cell.textLabel.text = title;
        //    if(originView){
        //    cell.textLabel.text =
        //        [NSString stringWithFormat:@"%@ size: %.2f*%.2f",title,
        //        originView.bounds.size.width,originView.bounds.size.height];
        //    }
    }

    return cell;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    id instance = [self.instances objectAtIndex:indexPath.row];
    FLEXObjectExplorerViewController *drillInViewController =
            [FLEXObjectExplorerFactory explorerViewControllerForObject:instance];
    [self.navigationController pushViewController:drillInViewController animated:YES];
}

@end
