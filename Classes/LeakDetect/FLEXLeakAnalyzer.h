//
//  FLEXLeakAnalyzer.h
//  FLEXCore
//
//  Created by viczxwang on 15/11/6.
//  Copyright © 2015年 OMG. All rights reserved.
//  对每次传入的 FLEXLeakOneDetectInfo 进行分析
//  分析结束后将 分析结果 FLEXLeakOneAnalyzerResult  传给 FLEXLeakAnalyzerResultDataSource

#import <Foundation/Foundation.h>

@class FLEXLeakOneDetectInfo;
@class FLEXLeakOneAnalyzerResult;

@interface FLEXLeakAnalyzerResultDataSource : NSObject
@property(nonatomic, strong) NSMutableArray *analyzerResultArray;

- (void)addOneAnalyzerResult:(FLEXLeakOneAnalyzerResult *)lastAnalyzerResult;

@end

@protocol FLEXLeakAnalyzerDelegate<NSObject>

- (void)oneAnalyzerDidFinish:(FLEXLeakAnalyzerResultDataSource *)resultDataSource;

@end

@interface FLEXLeakAnalyzer : NSObject

@property(nonatomic, weak) id<FLEXLeakAnalyzerDelegate> analyzerDelegate;

- (void)addOneDetectInfo:(FLEXLeakOneDetectInfo *)oneDetectInfo;
- (void)endAndClear;


@end
