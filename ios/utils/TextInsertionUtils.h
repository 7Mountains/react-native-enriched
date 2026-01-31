#import <UIKit/UIKit.h>

@interface TextInsertionUtils : NSObject
+ (void)insertText:(NSString *)text
                      at:(NSInteger)index
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id)input
           withSelection:(BOOL)withSelection;
+ (void)replaceText:(NSString *)text
                      at:(NSRange)range
    additionalAttributes:
        (NSDictionary<NSAttributedStringKey, id> *)additionalAttrs
                   input:(id)input
           withSelection:(BOOL)withSelection;
;
+ (void)insertEscapingParagraphsAtIndex:(NSUInteger)index
                                   text:(NSString *)text
                             attributes:
                                 (NSDictionary<NSAttributedStringKey, id> *)
                                     attributes
                                  input:(id)input
                          withSelection:(BOOL)withSelection;
@end
