#import "BaseStyleProtocol.h"
#import "StyleContext.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface StylesStack : NSObject

- (void)pushStyle:(id<BaseStyleProtocol>)style
       attributes:(NSDictionary *)attributes;

- (void)popStyle:(id<BaseStyleProtocol>)style;

- (void)applyStylesToAttributedString:(NSMutableAttributedString *)string
                                range:(NSRange)range;

@end
