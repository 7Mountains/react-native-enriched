#pragma once
#import <UIKit/UIKit.h>

@class AffectedWord;

@interface WordsUtils : NSObject
+ (NSArray<AffectedWord *> *)getAffectedWordsFromText:(NSString *)text
                                    modificationRange:(NSRange)range;
+ (AffectedWord *)getCurrentWord:(NSString *)text range:(NSRange)range;
@end
