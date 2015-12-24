//
//  FLEXDetectImagesTableViewController.m
//  FLEX
//
//  Created by viczxwang on 15/12/19.
//  Copyright © 2015年 Flipboard. All rights reserved.
//

#import "FLEXDetectImagesTableViewController.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>
#import "FLEXHeapEnumerator.h"
#import "FLEXRuntimeUtility.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXObjectExplorerViewController.h"

@interface FLEXDetectImagesTableViewController ()
@property(nonatomic, strong) NSArray *instances;
@end

@implementation FLEXDetectImagesTableViewController

- (void)viewDidLoad {
    self.title = @"Detect images";
    [super viewDidLoad];

    NSMutableArray *instances = [NSMutableArray array];
    [FLEXHeapEnumerator
            enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
                NSString *className = NSStringFromClass(actualClass);
                if ([className isEqualToString:@"UIImage"] || [self p_checkShouldDetectWithClass:actualClass]) {
                    [instances addObject:object];
                    //|| [className isEqualToString:@"UIImageView"]
                }
            }];

    [instances sortUsingComparator:^NSComparisonResult(id first, id second) {

        UIImage *firstoriginImage = nil;
        if ([first isKindOfClass:[UIImageView class]]) {
            firstoriginImage = ((UIImageView *)first).image;
        } else if ([first isKindOfClass:[UIImage class]]) {
            firstoriginImage = (UIImage *)first;
        }

        UIImage *secondoriginImage = nil;
        if ([second isKindOfClass:[UIImageView class]]) {
            secondoriginImage = ((UIImageView *)second).image;
        } else if ([second isKindOfClass:[UIImage class]]) {
            secondoriginImage = (UIImage *)second;
        }

        return (firstoriginImage.size.height * firstoriginImage.size.width) <
               (secondoriginImage.size.height * secondoriginImage.size.width);

    }];

    self.instances = instances;
}

- (BOOL)p_checkShouldDetectWithClass:(Class)oneclass {
    if (class_getSuperclass(oneclass) && class_getSuperclass(oneclass) != [NSObject class]) {
        if (class_getSuperclass(oneclass) == [UIImage class]) {
            // || class_getSuperclass(oneclass) == [UIImageView class]
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

    id instance = [self.instances objectAtIndex:indexPath.row];
    NSString *title = nil;

    UIImage *originImage = nil;
    if ([instance isKindOfClass:[UIImageView class]]) {
        originImage = ((UIImageView *)instance).image;
    } else if ([instance isKindOfClass:[UIImage class]]) {
        originImage = (UIImage *)instance;
    }
    cell.imageView.image = originImage;

    title = [NSString stringWithFormat:@"%@ %p", NSStringFromClass(object_getClass(instance)), instance];

    if (originImage) {
        cell.textLabel.text = [NSString
                stringWithFormat:@"%@ size: %.2f*%.2f", title, originImage.size.width, originImage.size.height];
    } else {
        cell.textLabel.text = title;
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
