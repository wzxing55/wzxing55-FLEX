//
//  FLEXLeakDetectSettingsTableViewController.m
//  FLEX
//
//  Created by viczxwang on 15/12/19.
//  Copyright © 2015年 Flipboard. All rights reserved.
//

#import "FLEXLeakDetectSettingsTableViewController.h"
#import "FLEXLeakDetect.h"
#import "FLEXUtility.h"

@interface FLEXLeakDetectSettingsTableViewController ()

@property (nonatomic, copy) NSArray *cells;

@end


@implementation FLEXLeakDetectSettingsTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSMutableArray *mutableCells = [NSMutableArray array];

    UITableViewCell *leakDetectCell = [self switchCellWithTitle:@"LeakDetect detecting" toggleAction:@selector(leakDetectToggled:) isOn:[[FLEXLeakDetect sharedInstance] isEnabled]];
    [mutableCells addObject:leakDetectCell];


    self.cells = mutableCells;
}

#pragma mark - Settings Actions

- (void)leakDetectToggled:(UISwitch *)sender
{
    [[FLEXLeakDetect sharedInstance] enableDetect:sender.isOn];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.cells count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.cells objectAtIndex:indexPath.row];
}

#pragma mark - Helpers

- (UITableViewCell *)switchCellWithTitle:(NSString *)title toggleAction:(SEL)toggleAction isOn:(BOOL)isOn
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = title;
    cell.textLabel.font = [[self class] cellTitleFont];

    UISwitch *theSwitch = [[UISwitch alloc] init];
    theSwitch.on = isOn;
    [theSwitch addTarget:self action:toggleAction forControlEvents:UIControlEventValueChanged];

    CGFloat switchOriginY = round((cell.contentView.frame.size.height - theSwitch.frame.size.height) / 2.0);
    CGFloat switchOriginX = CGRectGetMaxX(cell.contentView.frame) - theSwitch.frame.size.width - self.tableView.separatorInset.left;
    theSwitch.frame = CGRectMake(switchOriginX, switchOriginY, theSwitch.frame.size.width, theSwitch.frame.size.height);
    theSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [cell.contentView addSubview:theSwitch];

    return cell;
}

+ (UIFont *)cellTitleFont
{
    return [FLEXUtility defaultFontOfSize:14.0];
}

@end
