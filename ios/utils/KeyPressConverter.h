#pragma once

@interface KeyPressConverter : NSObject
+ (NSString *)keyFromText:(NSString *)text range:(NSRange)range;
@end
