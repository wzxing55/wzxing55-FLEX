//
//  FLEXLeakOneAnalyzerResult.m
//  FLEXCore
//
//  Created by viczxwang on 15/11/10.
//  Copyright © 2015年 OMG. All rights reserved.
//

#import "FLEXLeakOneAnalyzerResult.h"
#import "FLEXLeakOneDetectInfo.h"

#define _kDangerScoreWhenIncrement 3
#define _kDangerScoreWhenStay 0
#define _kDangerScoreWhenLowAveage -1

/*
 *  算danger 算法 = _kDangerScoreWhenIncrement + _kDangerScoreWhenStay + _kDangerScoreWhenLowAveage
 * 平均值
 *  如果逻辑上泄露会有几种情况
 * 1 、一致在慢慢涨，数量从不减少
 * 2、 有增加有减少，但是总趋势一致在增长
 *
 */

@implementation FLEXLeakDetectObjectModel

- (instancetype)initWithClassName:(NSString *)className {
    self = [super init];
    if (self) {
        _className = className;
        _num = 0;
        _incrementNum = 0;
        _stayNum = 0;
        _repeatIncreamNum = 0;
    }
    return self;
}

- (NSString *)description {
    return [NSString
            stringWithFormat:@"类名:%@;危险数值:%zd;存在数量:%zd;连续增长次数:%zd;比上次增加:%"
                             @"zd;",  // stayNum:%zd
                             self.className,
                             self.dangerScroe,
                             self.num,
                             self.repeatIncreamNum,
                             self.incrementNum];
    // self.stayNum];
}

@end

@interface FLEXLeakOneAnalyzerResult ()

//用于搜索
@property(nonatomic, strong) NSMutableDictionary *allClassDic;

@end

@implementation FLEXLeakOneAnalyzerResult
- (instancetype)init {
    self = [super init];
    if (self) {
        _resultObject = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithDetectInfo:(FLEXLeakOneDetectInfo *)oneDetectInfo {
    self = [self init];
    _detectTime = oneDetectInfo.detectTime;

    _allClassDic = [NSMutableDictionary dictionary];
    [self p_initLeakDetectObject:oneDetectInfo.liveObjects];
    return self;
}

- (void)diffWithLastAnalyzerResult:(FLEXLeakOneAnalyzerResult *)oneResult {
    if (oneResult && _detectTime > oneResult.detectTime) {
        // 确定是上一条

        [self.resultObject enumerateObjectsUsingBlock:^(FLEXLeakDetectObjectModel *object, NSUInteger idx, BOOL *stop) {

            FLEXLeakDetectObjectModel *thelast = [oneResult searchLeakDetectObjectModel:object.className];
            if (thelast) {
                object.stayNum = thelast.stayNum + 1;

                object.averageNum = (thelast.averageNum * thelast.stayNum + object.num) / object.stayNum;

                if (object.num > thelast.num) {
                    object.repeatIncreamNum = thelast.repeatIncreamNum + 1;
                    object.incrementNum = object.num - thelast.num;
                    object.dangerScroe = thelast.dangerScroe + _kDangerScoreWhenIncrement;
                } else if (object.num == thelast.num) {
                    object.dangerScroe = thelast.dangerScroe + _kDangerScoreWhenStay;
                } else {
                    if (object.averageNum < object.num) {
                        object.dangerScroe = thelast.dangerScroe + _kDangerScoreWhenLowAveage;
                    }
                }
            }

        }];

        [self p_sortResultObject];
    }
}

- (FLEXLeakDetectObjectModel *)searchLeakDetectObjectModel:(NSString *)className {

    if (className && [[self.allClassDic allKeys] containsObject:className]) {
        return self.allClassDic[className];
    }
    return nil;
}

- (void)p_initLeakDetectObject:(NSDictionary *)detectInfoDic {

    if (detectInfoDic) {
        //@weakify(self);
        FLEXLeakOneAnalyzerResult * __weak weakSelf = self;
        [detectInfoDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSNumber *obj, BOOL *stop) {

            //@strongify(self);
            FLEXLeakOneAnalyzerResult * __strong strongSelf = weakSelf;

            FLEXLeakDetectObjectModel *object = [[FLEXLeakDetectObjectModel alloc] initWithClassName:key];
            object.num = obj.integerValue;
            object.stayNum = 1;
            object.averageNum = obj.integerValue;
            [strongSelf.resultObject addObject:object];
            [strongSelf.allClassDic setObject:object forKey:key];
        }];
    }
}

- (void)p_sortResultObject {
    /*
     *  按照 dangerScroe、 repeatIncreamNum、 incrementNum、num 、stayNum 降序排序
     */
    if ([self.resultObject count]) {
        [self.resultObject sortUsingComparator:^NSComparisonResult(id first, id second) {
            
            FLEXLeakDetectObjectModel *firstModel = nil;// = AS(FLEXLeakDetectObjectModel, first);
        
            if([first isKindOfClass:[FLEXLeakDetectObjectModel class]]){
                firstModel = (FLEXLeakDetectObjectModel*)first;
            }
            FLEXLeakDetectObjectModel *secondModel = nil;//AS(FLEXLeakDetectObjectModel, second);
            if([second isKindOfClass:[FLEXLeakDetectObjectModel class]]){
                secondModel = (FLEXLeakDetectObjectModel*)second;
            }
            
            // AS_VAR(firstModel, FLEXLeakDetectObjectModel, first);
            // AS_VAR(secondModel, FLEXLeakDetectObjectModel, second);

            if (firstModel.dangerScroe == secondModel.dangerScroe) {

                if (firstModel.repeatIncreamNum == secondModel.repeatIncreamNum) {

                    if (firstModel.incrementNum == secondModel.incrementNum) {

                        if (firstModel.num == secondModel.num) {

                            if (firstModel.stayNum == secondModel.stayNum) {
                                return [firstModel.className compare:secondModel.className];

                            } else {
                                return firstModel.stayNum < secondModel.stayNum;
                            }

                        } else {
                            return firstModel.num < secondModel.num;
                        }

                    } else {
                        return firstModel.incrementNum < secondModel.incrementNum;
                    }

                } else {
                    return firstModel.repeatIncreamNum < secondModel.repeatIncreamNum;
                }

            } else {
                return firstModel.dangerScroe < secondModel.dangerScroe;
            }

        }];
    }
}

- (NSString *)message {

    __block NSMutableString *resultmessage = [NSMutableString string];

    if ([self.resultObject count]) {

        [resultmessage appendString:[NSString stringWithFormat:@"本次检测对象总数%zd", [self.resultObject count]]];
      
        FLEXLeakOneAnalyzerResult *__weak weakSelf = self;
        
        [self.resultObject enumerateObjectsUsingBlock:^(FLEXLeakDetectObjectModel *object, NSUInteger idx, BOOL *stop) {
            FLEXLeakOneAnalyzerResult *__strong strongSelf = weakSelf;
            if ([strongSelf p_shouldInNoticeObjects:object]) {
                [resultmessage appendString:[NSString stringWithFormat:@" notice them ! %@ \n", [object description]]];
            }
        }];
    }

    return resultmessage;
}

- (NSArray *)needNoticeObjectArray {

    NSMutableArray *needNoticeObjects = [NSMutableArray array];

    [self.resultObject enumerateObjectsUsingBlock:^(FLEXLeakDetectObjectModel *object, NSUInteger idx, BOOL *stop) {

        [needNoticeObjects addObject:object];
        //        if ([self p_shouldInNoticeObjects:object]) {
        //            [needNoticeObjects addObject:object];
        //        }

    }];

    return needNoticeObjects;
}

- (BOOL)p_shouldInNoticeObjects:(FLEXLeakDetectObjectModel *)object {

#warning for test
    return  YES;//object.dangerScroe > _kDangerScoreWhenIncrement * 3;
}

@end
