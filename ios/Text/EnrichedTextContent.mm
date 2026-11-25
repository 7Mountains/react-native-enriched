#import "EnrichedTextContent.h"
#import "AttachmentInvalidationBatcher.h"
#import "EnrichedLaidOutText.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextBuilder.h"
#import "EnrichedTextDrawingView.h"
#import "LayoutManagerExtension.h"

// Set to clear the text, the same for all the views
static NSAttributedString *EmptyText() {
  static NSAttributedString *const emptyText =
      [[NSAttributedString alloc] init];
  return emptyText;
}

@implementation EnrichedTextContent {
  __weak id<EnrichedStyleHost> _host;
  AttachmentInvalidationBatcher *_attachmentBatcher;
  NSInteger _maximumNumberOfLines;
  NSLineBreakMode _lineBreakMode;
  // The size of the text laid out by the measurement the view draws: its
  // container is kept while the view shows it as it's laid out
  BOOL _hasMeasuredLayout;
  CGSize _measuredLayoutSize;
}

- (instancetype)initWithHost:(id<EnrichedStyleHost>)host
                  selectable:(BOOL)selectable
        maximumNumberOfLines:(NSInteger)maximumNumberOfLines
               lineBreakMode:(NSLineBreakMode)lineBreakMode {
  if (self = [super init]) {
    _host = host;
    _isSelectable = selectable;
    _maximumNumberOfLines = maximumNumberOfLines;
    _lineBreakMode = lineBreakMode;

    // TextKit 1, as the measurement (EnrichedTextBuilder) and the drawing of
    // the paragraphs (LayoutManagerExtension)
    _textStorage = [[NSTextStorage alloc] init];
    _layoutManager = [[NSLayoutManager alloc] init];
    _textContainer =
        [[NSTextContainer alloc] initWithSize:CGSizeMake(0, CGFLOAT_MAX)];
    _textContainer.widthTracksTextView = NO;
    _textContainer.heightTracksTextView = NO;
    [EnrichedTextBuilder configureTextContainer:_textContainer
                           maximumNumberOfLines:maximumNumberOfLines
                                  lineBreakMode:lineBreakMode];
    [_layoutManager addTextContainer:_textContainer];
    [_textStorage addLayoutManager:_layoutManager];
    _layoutManager.input = host;

    if (selectable) {
      UITextView *textView = [[UITextView alloc] initWithFrame:CGRectZero
                                                 textContainer:_textContainer];
      textView.editable = NO;
      textView.selectable = YES;
      textView.scrollEnabled = NO;
      textView.backgroundColor = UIColor.clearColor;
      textView.textContainerInset = UIEdgeInsetsZero;
      textView.dataDetectorTypes = UIDataDetectorTypeNone;
      textView.textDragInteraction.enabled = NO;
      _view = textView;
      _textView = textView;
      _attachmentBatcher =
          [[AttachmentInvalidationBatcher alloc] initWithTextView:textView];
    } else {
      _view = [[EnrichedTextDrawingView alloc]
          initWithTextContainer:_textContainer];
    }
  }
  return self;
}

// The drawing view is told when its text or the layout of it changes: a text
// view follows them itself
- (void)setNeedsTextDisplay {
  if (!_isSelectable) {
    [_view setNeedsDisplay];
  }
}

- (void)setMaximumNumberOfLines:(NSInteger)maximumNumberOfLines
                  lineBreakMode:(NSLineBreakMode)lineBreakMode {
  _maximumNumberOfLines = maximumNumberOfLines;
  _lineBreakMode = lineBreakMode;
  [EnrichedTextBuilder configureTextContainer:_textContainer
                         maximumNumberOfLines:maximumNumberOfLines
                                lineBreakMode:lineBreakMode];
  [self setNeedsTextDisplay];
}

- (void)setPreparedText:(EnrichedPreparedText *)preparedText {
  _preparedText = preparedText;

  if (![self adoptLaidOutTextOf:preparedText]) {
    // As high as the text needs, and drawn as wide as the view: emptied
    // first, the previous text isn't laid out again for it
    NSTextContainer *textContainer = _textContainer;
    CGFloat width =
        _isSelectable ? textContainer.size.width : _view.frame.size.width;
    if (textContainer.size.height != CGFLOAT_MAX ||
        textContainer.size.width != width) {
      [_textStorage setAttributedString:EmptyText()];
      textContainer.size = CGSizeMake(width, CGFLOAT_MAX);
    }

    [_textStorage setAttributedString:preparedText.text];
    _hasMeasuredLayout = NO;
  }
  [self setNeedsTextDisplay];

  // Built for a host without a view: the attachments are redrawn by this one
  // once their images load
  id<EnrichedStyleHost> host = _host;
  [_textStorage enumerateAttribute:NSAttachmentAttributeName
                           inRange:NSMakeRange(0, _textStorage.length)
                           options:0
                        usingBlock:^(id value, NSRange range, BOOL *stop) {
                          if ([value isKindOfClass:[MediaAttachment class]]) {
                            ((MediaAttachment *)value).delegate = host;
                          }
                        }];
}

- (void)setFrame:(CGRect)frame nextText:(EnrichedPreparedText *)nextText {
  BOOL isOtherTextNext = nextText != nil && nextText != _preparedText;

  // Only a text view lays its text out again as it's resized: emptied first
  // when another text comes. The drawing view leaves its container for that
  // text (see `fitTextContainerBeforeText:`)
  if (_isSelectable && isOtherTextNext && _textStorage.length > 0 &&
      !CGSizeEqualToSize(_view.frame.size, frame.size)) {
    [_textStorage setAttributedString:EmptyText()];
  }

  if (!CGRectEqualToRect(_view.frame, frame)) {
    _view.frame = frame;
  }
  [self fitTextContainerBeforeText:nextText];
}

// As wide as the view and, as in the measurement, as high as the text needs:
// with the height of the view, rounded, the last line could be left out. Not
// resized when the text already fits: each resize lays it out again
- (void)fitTextContainerBeforeText:(EnrichedPreparedText *)nextText {
  NSTextContainer *textContainer = _textContainer;
  CGFloat width = _view.frame.size.width;

  if (!_isSelectable) {
    // Another text comes after, with its own layout or its container set for
    // it: resized now, this one would be laid out again for nothing
    if (nextText != nil && nextText != _preparedText) {
      return;
    }

    // Measured again for the new size: drawn as it's laid out
    if ([self adoptLaidOutTextOf:_preparedText]) {
      return;
    }

    // Laid out by the measurement in a container as wide as the view could
    // be: kept while the view shows it as it is (e.g. moved in a list)
    CGSize size = _view.frame.size;
    if (_hasMeasuredLayout && _preparedText.isLaidOutAtAnyWidth &&
        fabs(size.height - _measuredLayoutSize.height) <= 0.5 &&
        size.width >= _measuredLayoutSize.width - 0.5 &&
        size.width <= textContainer.size.width + 0.5) {
      return;
    }
  }

  if (textContainer.size.width == width &&
      (textContainer.size.height == CGFLOAT_MAX || [self isTextLaidOut])) {
    return;
  }

  textContainer.size = CGSizeMake(width, CGFLOAT_MAX);
  _hasMeasuredLayout = NO;
  [self setNeedsTextDisplay];
}

// The layout of the measurement on the layout thread, when it's the one the
// view shows: the text isn't laid out again on the main thread. Its
// attachments are the ones of the text, already redrawn by this view
- (BOOL)adoptLaidOutTextOf:(EnrichedPreparedText *)preparedText {
  if (_isSelectable || preparedText == nil) {
    return NO;
  }

  EnrichedLaidOutText *laidOutText =
      [preparedText takeLaidOutTextForSize:_view.frame.size
                      maximumNumberOfLines:_maximumNumberOfLines
                             lineBreakMode:_lineBreakMode];
  if (laidOutText == nil) {
    return NO;
  }

  _textStorage = laidOutText.textStorage;
  _layoutManager = laidOutText.layoutManager;
  _textContainer = laidOutText.textContainer;
  _layoutManager.input = _host;
  ((EnrichedTextDrawingView *)_view).textContainer = _textContainer;
  _hasMeasuredLayout = YES;
  _measuredLayoutSize = laidOutText.size;
  [self setNeedsTextDisplay];
  return YES;
}

// Whether the whole text is laid out in the container
- (BOOL)isTextLaidOut {
  NSRange glyphRange =
      [_layoutManager glyphRangeForTextContainer:_textContainer];
  return NSMaxRange(glyphRange) >= _layoutManager.numberOfGlyphs;
}

- (void)redrawAttachment:(MediaAttachment *)attachment {
  if (_attachmentBatcher != nil) {
    [_attachmentBatcher enqueueAttachment:attachment];
  } else {
    [_view setNeedsDisplay];
  }
}

- (void)clear {
  _preparedText = nil;
  [_textStorage setAttributedString:EmptyText()];
  _hasMeasuredLayout = NO;
  [self setNeedsTextDisplay];
}

@end
