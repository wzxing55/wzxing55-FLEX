//
//  FLEXLeakAnalyzer.m
//  FLEXCore
//
//  Created by viczxwang on 15/11/6.
//  Copyright © 2015年 OMG. All rights reserved.
//

#import "FLEXLeakAnalyzer.h"

#import <objc/runtime.h>
#import "FLEXLeakOneDetectInfo.h"
#import "FLEXLeakOneAnalyzerResult.h"

#define _kMaxDataSourceNum 2 // 只存放上一次和本次

@implementation FLEXLeakAnalyzerResultDataSource

- (instancetype)init
{
    self = [super init];
    if (self) {
        _analyzerResultArray = [NSMutableArray array];
    }
    return self;
}

- (void)addOneAnalyzerResult:(FLEXLeakOneAnalyzerResult *)lastAnalyzerResult
{
    if (lastAnalyzerResult) {
        if (_analyzerResultArray.count < _kMaxDataSourceNum) {
            [_analyzerResultArray addObject:lastAnalyzerResult];
        } else if (_analyzerResultArray.count == _kMaxDataSourceNum) {
            [_analyzerResultArray removeObjectAtIndex:0];
            [_analyzerResultArray addObject:lastAnalyzerResult];
        }
    }
}

@end

@interface FLEXLeakAnalyzer ()
/*
 *  每次分析的结果
 */
@property (nonatomic, strong) FLEXLeakOneAnalyzerResult *lastAnalyzerResult;

/*
 *  存储多次多次分析结果
 */
@property (nonatomic, strong) FLEXLeakAnalyzerResultDataSource *resultDataSource;

/*
 *  需要关注的对象
 */
@property (nonatomic, strong) NSArray *needNoticeObjects;

@end

@implementation FLEXLeakAnalyzer

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)addOneDetectInfo:(FLEXLeakOneDetectInfo *)oneDetectInfo
{
    if (oneDetectInfo) {

        if (!_lastAnalyzerResult) {
            //第一次 检测仅初始化 _lastAnalyzerResult  和 _resultDataSource
            _lastAnalyzerResult = [[FLEXLeakOneAnalyzerResult alloc] initWithDetectInfo:oneDetectInfo];
            _resultDataSource = [[FLEXLeakAnalyzerResultDataSource alloc] init];
            [_resultDataSource addOneAnalyzerResult:_lastAnalyzerResult];

        } else {
            // _lastAnalyzerResult 和 oneDetectInfo  对比
            FLEXLeakOneAnalyzerResult *newResult = [[FLEXLeakOneAnalyzerResult alloc] initWithDetectInfo:oneDetectInfo];
            /*
             *   新的和上一次对比，记录增长，平均值，危险分数等
             */
            [newResult diffWithLastAnalyzerResult:_lastAnalyzerResult];

            self.lastAnalyzerResult = newResult;

            if ([self.lastAnalyzerResult.message length]) {
                //  简易的一个结论输出
                // TODO  输入日志  ，严重 notice 提示
                NSLog(@"analyze meeeage : \n %@", [self.lastAnalyzerResult message]);

                if (self.analyzerDelegate &&
                    [self.analyzerDelegate respondsToSelector:@selector(oneAnalyzerDidFinish:)]) {
                    [self.analyzerDelegate oneAnalyzerDidFinish:self.resultDataSource];
                }
            }
            [self.resultDataSource addOneAnalyzerResult:self.lastAnalyzerResult];
        }
    }
}

- (void)endAndClear
{
    _lastAnalyzerResult = nil;
    _resultDataSource = nil;
}
@end
