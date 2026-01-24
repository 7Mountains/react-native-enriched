#import <Foundation/Foundation.h>

@class EnrichedTextInputView;

@interface EnrichedCommandHandler : NSObject

- (instancetype)initWithInput:(EnrichedTextInputView *)input;

- (void)handleCommand:(NSString *)commandName args:(NSArray *)args;

@end
