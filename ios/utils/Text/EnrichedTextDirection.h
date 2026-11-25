#pragma once
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Whether the lines of the text are laid out the same in any container they
// fit: its paragraphs are aligned to the left and written left to right,
// without a code block (its background is as wide as the container)
BOOL EnrichedIsTextLaidOutAtAnyWidth(NSAttributedString *text);

NS_ASSUME_NONNULL_END
