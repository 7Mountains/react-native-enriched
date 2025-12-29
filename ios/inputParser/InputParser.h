#pragma once
#import <UIKit/UIKit.h>

@class ConvertHtmlToPlainTextAndStylesResult;

@interface InputParser : NSObject
- (instancetype _Nonnull)initWithInput:(id _Nonnull)input;
- (NSString *_Nonnull)parseToHtmlFromRange:(NSRange)range;
- (void)parseToHtmlFromRangeAsync:(NSRange)range
                       completion:(void (^_Nonnull)(NSString *_Nonnull html))
                                      completion;
- (void)replaceWholeFromHtml:(NSString *_Nonnull)html
    notifyAnyTextMayHaveBeenModified:(BOOL)notifyAnyTextMayHaveBeenModified;
- (void)replaceFromHtml:(NSString *_Nonnull)html range:(NSRange)range;
- (void)insertFromHtml:(NSString *_Nonnull)html location:(NSInteger)location;
@end
