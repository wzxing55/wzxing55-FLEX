//
//  FLEXLeakOneDetectInfo.h
//  FLEXCore
//
//  Created by viczxwang on 15/11/9.
//  Copyright © 2015年 OMG. All rights reserved.
//  每次检测后

#import <Foundation/Foundation.h>


@interface FLEXLeakOneDetectInfo : NSObject
/*
 *  发生检测的时间
 */
@property(nonatomic, assign) CFAbsoluteTime detectTime;
/*
 *  存放 FLEXLeakDetectObjectModel
 */
@property(nonatomic, strong) NSMutableDictionary *liveObjects;
@end
