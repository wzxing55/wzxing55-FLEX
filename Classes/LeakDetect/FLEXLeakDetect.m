//
//  FLEXLeakDetect.m
//  FLEXCore
//
//  Created by viczxwang on 15/11/5.
//  Copyright © 2015年 OMG. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "FLEXLeakDetect.h"

#import <objc/runtime.h>
#import "FLEXLeakOneDetectInfo.h"
#import "FLEXHeapEnumerator.h"

@interface FLEXLeakDetect ()
/*
 *   目的是能够间隔一定时间循环调用 detect 在Heap获取liveObject
 *   在非主线程 FLEXHeapEnumerator enumerateLiveObjectsUsingBlock  非常容易崩溃掉
 */
@property(nonatomic, strong) NSTimer *detectTimer;
@property(nonatomic, assign, readwrite) BOOL isEnabled;
@property(nonatomic, assign) BOOL isDetecting;

// 应该被检测的对象 集合
@property(nonatomic, strong) NSSet *shouldDetectObject;

// 不检测的对象集合 包括FLEXLeakDetectObjectModel FLEXLeakOneAnalyzerResult
//  这两个随着检测进行必然会不断增长
@property(nonatomic, strong) NSSet *shouldNotDetectObject;

@end

@implementation FLEXLeakDetect

static dispatch_source_t FLEX_leakDetet_rollingTimer;

static NSTimeInterval period = 5.0;  //设置时间间隔

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static FLEXLeakDetect *leakDetect;
    dispatch_once(&once,
                  ^{
                      leakDetect = [[FLEXLeakDetect alloc] init];
                  });
    return leakDetect;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isDetecting = NO;
        _analyzer = [[FLEXLeakAnalyzer alloc] init];
        _shouldDetectObject = [NSSet setWithObjects:@"UIView", @"UIImage", @"UIViewController", @"UIImageView", nil];
        _shouldNotDetectObject = [NSSet setWithObjects:@"FLEXLeakDetectObjectModel", @"FLEXLeakOneAnalyzerResult", nil];
    }
    return self;
}

- (void)dealloc {
    [self.detectTimer invalidate];
    self.detectTimer = nil;
}

- (void)enableDetect:(BOOL)enable {
    self.isEnabled = enable;
    if (enable) {
        if (!_isDetecting) {
            [self beiginDetect];
        }
    } else {
        if (_isDetecting) {
            [self endDetect];
        }
    }
}

- (void)beiginDetect {
    _isDetecting = YES;

    if (self.detectTimer) {
        [self.detectTimer invalidate];
        self.detectTimer = nil;
    }
    self.detectTimer =
            [NSTimer timerWithTimeInterval:period target:self selector:@selector(detect) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.detectTimer forMode:NSDefaultRunLoopMode];
}

- (void)endDetect {
    _isDetecting = NO;
    if (self.detectTimer) {
        [self.detectTimer invalidate];
        self.detectTimer = nil;
    }

    [self.analyzer endAndClear];
}

- (void)detect {
    //  找heap live 对象
    @autoreleasepool {

        FLEXLeakOneDetectInfo *info = [[FLEXLeakOneDetectInfo alloc] init];
        info.detectTime = CFAbsoluteTimeGetCurrent();
        info.liveObjects = [NSMutableDictionary dictionary];

        unsigned int classCount = 0;
        Class *classes = objc_copyClassList(&classCount);
        CFMutableDictionaryRef mutableCountsForClasses = CFDictionaryCreateMutable(NULL, classCount, NULL, NULL);

        unsigned int checkClassCount = 0;
        for (unsigned int i = 0; i < classCount; i++) {
            NSString *className = NSStringFromClass(classes[i]);
            if ([self p_checkShouldDetect:className] || [self p_checkShouldDetectWithClass:classes[i]]) {
                checkClassCount++;
                CFDictionarySetValue(mutableCountsForClasses, (__bridge const void *)classes[i], (const void *)0);
            }
        }

        // Enumerate all objects on the heap to build the counts of instances for each class.
        [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object,
                                                             __unsafe_unretained Class actualClass) {

            if (CFDictionaryContainsKey(mutableCountsForClasses, (__bridge const void *)actualClass)) {

                NSUInteger instanceCount =
                        (NSUInteger)CFDictionaryGetValue(mutableCountsForClasses, (__bridge const void *)actualClass);
                instanceCount++;
                CFDictionarySetValue(
                        mutableCountsForClasses, (__bridge const void *)actualClass, (const void *)instanceCount);
            }
        }];

        // 给分析程序

        for (unsigned int i = 0; i < classCount; i++) {
            Class class = classes[i];
            if (CFDictionaryContainsKey(mutableCountsForClasses, (__bridge const void *)class)) {

                NSUInteger instanceCount =
                        (NSUInteger)CFDictionaryGetValue(mutableCountsForClasses, (__bridge const void *)(class));
                if (instanceCount > 0) {
                    NSString *className = @(class_getName(class));
                    [info.liveObjects setObject:@(instanceCount) forKey:className];
                }
            }
        }

        [self.analyzer addOneDetectInfo:info];
        free(classes);

        NSLog(@"operation took %2.5f seconds", CFAbsoluteTimeGetCurrent() - info.detectTime);
        NSLog(@" detecting ......");
    }
}

- (BOOL)p_checkShouldDetect:(NSString *)className {
    return ([className hasPrefix:@"UI"] || [className hasPrefix:@"FLEX"] || [className hasPrefix:@"KB"] ||
            [self.shouldDetectObject containsObject:className]) &&
           (![self.shouldNotDetectObject containsObject:className]);
}

- (BOOL)p_checkShouldDetectWithClass:(Class)oneclass {
    if (class_getSuperclass(oneclass) && class_getSuperclass(oneclass) != [NSObject class]) {
        if (class_getSuperclass(oneclass) == [UIView class] ||
            class_getSuperclass(oneclass) == [UIViewController class]) {
            return YES;
        } else {
            return [self p_checkShouldDetectWithClass:class_getSuperclass(oneclass)];
        }
    }
    return NO;
}

- (void)closeDetect {
    self.analyzer.analyzerDelegate = nil;
    [self endDetect];
}
@end
