#pragma once
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) &&                                \
    __IPHONE_OS_VERSION_MAX_ALLOWED >= 180000
@interface NSString (WritingToolsBehavior)

- (UIWritingToolsBehavior)writingToolsBehavior API_AVAILABLE(ios(18.0));

@end
#endif
