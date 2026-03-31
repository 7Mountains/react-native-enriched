#pragma once
#import "BaseStyleProtocol.h"
#import <UIKit/UIKit.h>

@interface InputParser : NSObject
- (NSString *_Nonnull)
    parseToHtml:(NSAttributedString *_Nonnull)attributedString
         styles:
             (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *_Nonnull)styles;

- (void)parseToHTMLAsync:(NSAttributedString *_Nonnull)attributedString
                  styles:(NSDictionary<NSNumber *, id<BaseStyleProtocol>>
                              *_Nonnull)styles
                prettify:(BOOL)prettify
              completion:(void (^_Nonnull)(NSString *_Nullable html,
                                           NSError *_Nullable error))completion;
- (NSMutableAttributedString *_Nonnull)
    attributedFromHtml:

        (NSString *_Nonnull)html
                styles:
                    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *_Nonnull)
                        styles
     defaultAttributes:(NSDictionary *_Nonnull)defaultAttributes;

- (BOOL)isHtmlString:(NSString *_Nullable)string;
@end
