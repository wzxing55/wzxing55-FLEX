//
//  FLEXLeakOneAnalyzerResult.h
//  FLEXCore
//
//  Created by viczxwang on 15/11/10.
//  Copyright © 2015年 OMG. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * 对单个检测出来的对象统计上的描述
 */
@interface FLEXLeakDetectObjectModel : NSObject

/*
 *  对应的className
 */
@property(nonatomic, copy) NSString *className;

/*
 *  本次检测出来的数量
 */
@property(nonatomic, assign) NSInteger num;

/*
 *  比上一次增长的数量  本次减上一次
 */
@property(nonatomic, assign) NSInteger incrementNum;

/*
 *  连续被检测出来的次数，代表常驻次数
 */
@property(nonatomic, assign) NSInteger stayNum;

/*
 *  连续增长的次数  多次增长需要warning
 */
@property(nonatomic, assign) NSInteger repeatIncreamNum;

/*
 * 可能泄露的危险分数
 */
@property(nonatomic, assign) NSInteger dangerScroe;

/*
 * 平均数
 */
@property(nonatomic, assign) NSInteger averageNum;

- (instancetype)initWithClassName:(NSString *)className;

- (NSString *)description;
@end

@class FLEXLeakOneDetectInfo;

/*
 *  每一次检测的后的分析结果
 */
@interface FLEXLeakOneAnalyzerResult : NSObject

@property(nonatomic, assign) CFAbsoluteTime detectTime;

// 记录统计后的可能有疑问的对象和结论
@property(nonatomic, copy) NSString *message;

/*
 *
 */
@property(nonatomic, strong) NSMutableArray *resultObject;

- (instancetype)initWithDetectInfo:(FLEXLeakOneDetectInfo *)oneDetectInfo;

//与上一条做对比
- (void)diffWithLastAnalyzerResult:(FLEXLeakOneAnalyzerResult *)oneResult;

/*
 *  通过classname，查找 FLEXLeakDetectObjectModel, diffWithLastAnalyzerResult 中使用
 */
- (FLEXLeakDetectObjectModel *)searchLeakDetectObjectModel:(NSString *)className;

- (NSArray *)needNoticeObjectArray;

@end
