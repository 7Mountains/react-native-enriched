#pragma once
#import <UIKit/UIKit.h>

@class ConvertHtmlToPlainTextAndStylesResult;

@interface InputParser : NSObject
- (instancetype _Nonnull)initWithInput:(id _Nonnull)input;
- (NSString *_Nonnull)parseToHtmlFromRange:(NSRange)range;
- (void)parseToHTMLAsync:(BOOL)prettify
              completion:(void (^_Nonnull)(NSString *_Nullable html,
                                           NSError *_Nullable error))completion;
- (NSMutableAttributedString *_Nonnull)attributedFromHtml:
    (NSString *_Nonnull)html;
- (BOOL)isHtmlString:(NSString *_Nullable)string;
@end
