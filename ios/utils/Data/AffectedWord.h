//
//  AffectedWord.h
//  Pods
//
//  Created by Ivan Ignathuk on 26/05/2026.
//

@interface AffectedWord : NSObject

@property(nonatomic, copy, readonly) NSString *text;
@property(nonatomic, assign, readonly) NSRange range;

- (instancetype)initWithText:(NSString *)text range:(NSRange)range;

@end
