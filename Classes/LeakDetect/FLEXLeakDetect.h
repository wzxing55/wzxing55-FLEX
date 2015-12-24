//
//  FLEXLeakDetect.h
//  FLEXCore
//
//  Created by viczxwang on 15/11/5.
//  Copyright © 2015年 OMG. All rights reserved.
//  检测程序逻辑上可能的leak，例如长期一直增长的对象
//

#import <Foundation/Foundation.h>
#import "FLEXLeakAnalyzer.h"

@interface FLEXLeakDetect : NSObject

@property(nonatomic, strong) FLEXLeakAnalyzer *analyzer;
@property(nonatomic, assign, readonly) BOOL isEnabled;

+ (instancetype)sharedInstance;

/*
 *  是否开始检测
 */
- (void)enableDetect:(BOOL)enable;
@end
