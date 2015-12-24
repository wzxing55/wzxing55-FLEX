//
//  FLEXDetectViewControllerTableViewController.m
//  FLEX
//
//  Created by viczxwang on 15/12/20.
//  Copyright © 2015年 Flipboard. All rights reserved.
//

#import "FLEXDetectViewControllerTableViewController.h"
#import "FLEXHeapEnumerator.h"
#import <objc/runtime.h>
#import "FLEXUtility.h"
#import "FLEXObjectExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"

@interface FLEXDetectViewControllerTableViewController ()
@property (nonatomic, strong) NSArray *instances;
@end


@implementation FLEXDetectViewControllerTableViewController


- (void)viewDidLoad
{
    self.title = @"Detect viewController";
    [super viewDidLoad];

    NSMutableArray *instances = [NSMutableArray array];
    [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
        if(object){
            NSString *className = NSStringFromClass(actualClass);
            if ([className isEqualToString:@"UIViewController"] ||
                [self p_checkShouldDetectWithClass:actualClass]
                ) {
                if(![className hasPrefix:@"_"]){
                    [instances addObject:object];
                }
            }
        }
    }];

    [instances sortUsingComparator:^NSComparisonResult(id first, id second) {
         UIViewController * uv1 = (UIViewController*)first;
         UIViewController * uv2 = (UIViewController*)second;
         return uv1.view.frame.size.width* uv1.view.frame.size.height >
                uv2.view.frame.size.width* uv2.view.frame.size.height;



    }];

    self.instances = instances;
}

- (BOOL)p_checkShouldDetectWithClass:(Class)oneclass
{
    if (class_getSuperclass(oneclass) && class_getSuperclass(oneclass) != [NSObject class]) {
        if (class_getSuperclass(oneclass) == [UIViewController class]) {
            return YES;
        } else {
            return [self p_checkShouldDetectWithClass:class_getSuperclass(oneclass)];
        }
    }
    return NO;
}


#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.instances count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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

    id instance = [self.instances objectAtIndex:indexPath.row];
    NSString *title = nil;


    UIView *originView = nil;

    if ([instance isKindOfClass:[UIView class]]) {
        originView = (UIView *)instance;
    }
    title = [NSString stringWithFormat:@"%@ %p", NSStringFromClass(object_getClass(instance)), instance];
    cell.textLabel.text = title;


    return cell;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    id instance = [self.instances objectAtIndex:indexPath.row];
    FLEXObjectExplorerViewController *drillInViewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:instance];
    [self.navigationController pushViewController:drillInViewController animated:YES];
}
@end
