#pragma once
#import "EnrichedStyleHost.h"
#import <UIKit/UIKit.h>

@class EnrichedPreparedText;

NS_ASSUME_NONNULL_BEGIN

// The text of EnrichedTextView and the view showing it: a text view only when
// it's selectable, otherwise a lighter view drawing it. Both lay it out with
// a TextKit 1 stack: the one of the measurement, when it's laid out for the
// size of the view (see EnrichedLaidOutText)
@interface EnrichedTextContent : NSObject

@property(nonatomic, readonly) UIView *view;
// Only when the text is selectable: the drawing reads the text of its layout
// manager
@property(nonatomic, readonly, nullable) UITextView *textView;
@property(nonatomic, readonly) NSTextStorage *textStorage;
@property(nonatomic, readonly) NSLayoutManager *layoutManager;
@property(nonatomic, readonly) NSTextContainer *textContainer;
@property(nonatomic, readonly, nullable) EnrichedPreparedText *preparedText;
@property(nonatomic, readonly) BOOL isSelectable;

// The host draws the paragraphs (LayoutManagerExtension) and is told when
// the images of the attachments load
- (instancetype)initWithHost:(id<EnrichedStyleHost>)host
                  selectable:(BOOL)selectable
        maximumNumberOfLines:(NSInteger)maximumNumberOfLines
               lineBreakMode:(NSLineBreakMode)lineBreakMode
    NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)setMaximumNumberOfLines:(NSInteger)maximumNumberOfLines
                  lineBreakMode:(NSLineBreakMode)lineBreakMode;
- (void)setPreparedText:(EnrichedPreparedText *)preparedText;
// The text set next, when it's known: the current one isn't laid out again
// for the frame before it
- (void)setFrame:(CGRect)frame
        nextText:(nullable EnrichedPreparedText *)nextText;
- (void)redrawAttachment:(MediaAttachment *)attachment;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
