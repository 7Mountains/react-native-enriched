#import "InputTextView.h"
#import "EnrichedTextInputView.h"
#import "ParagraphsUtils.h"
#import "StringExtension.h"
#import "Strings.h"
#import "TextInsertionUtils.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static inline BOOL CGSizeAlmostEqual(CGSize firstSize, CGSize secondSize,
                                     CGFloat epsilon) {
  return fabs(firstSize.width - secondSize.width) < epsilon &&
         fabs(firstSize.height - secondSize.height) < epsilon;
}

@interface InputTextView ()
- (void)notifySizeDidChangeForContentSize:(CGSize)contentSize;
@end

@implementation InputTextView {
  UILabel *_placeholderView;
  CGSize _lastCommittedSize;
};

- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    _placeholderView = [[UILabel alloc] initWithFrame:self.bounds];
    _placeholderView.isAccessibilityElement = NO;
    _placeholderView.numberOfLines = 1;
    _placeholderView.adjustsFontForContentSizeCategory = YES;
    [self addSubview:_placeholderView];

    self.textContainer.lineFragmentPadding = 0;
    self.scrollEnabled = YES;
    self.scrollsToTop = NO;
    self.alwaysBounceVertical = YES;
    _lastCommittedSize = CGSizeZero;
  }
  return self;
}

- (void)copy:(id)sender {
  [self.clipboardDelegate handleCopyFromTextView:self sender:sender];
}

- (void)paste:(id)sender {
  [self.clipboardDelegate handlePasteIntoTextView:self sender:sender];
}

- (void)cut:(id)sender {
  [self.clipboardDelegate handleCutFromTextView:self sender:sender];
}

- (void)updatePlaceholderVisibility {
  BOOL shouldShow =
      self.placeholderText.length > 0 && self.textStorage.length == 0;

  _placeholderView.hidden = !shouldShow;
}

- (void)setText:(NSString *)text {
  [super setText:text];
  [self updatePlaceholderVisibility];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
  [super setAttributedText:attributedText];
  [self updatePlaceholderVisibility];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
  _placeholderColor = placeholderColor;
  [self refreshPlaceholder];
}

- (void)setPlaceholderText:(NSString *)newPlaceholderText {
  _placeholderText = newPlaceholderText;
  [self refreshPlaceholder];
}

- (void)setTypingAttributes:
    (NSDictionary<NSAttributedStringKey, id> *)typingAttributes {
  [super setTypingAttributes:typingAttributes];
  if (self.textStorage.length == 0) {
    [self refreshPlaceholder];
  }
}

- (void)refreshPlaceholder {
  NSMutableDictionary *attributes = self.typingAttributes.mutableCopy;

  if (_placeholderColor) {
    attributes[NSForegroundColorAttributeName] = _placeholderColor;
    attributes[NSUnderlineColorAttributeName] = _placeholderColor;
    attributes[NSStrikethroughColorAttributeName] = _placeholderColor;
  }

  NSString *placeholder = _placeholderText ?: @"";

  _placeholderView.attributedText =
      [[NSAttributedString alloc] initWithString:placeholder
                                      attributes:attributes];

  [self updatePlaceholderVisibility];

  [self setNeedsLayout];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  UIEdgeInsets contentInsets = self.adjustedContentInset;

  UIEdgeInsets combinedInsets =
      UIEdgeInsetsMake(self.textContainerInset.top + contentInsets.top,
                       self.textContainerInset.left + contentInsets.left,
                       self.textContainerInset.bottom + contentInsets.bottom,
                       self.textContainerInset.right + contentInsets.right);

  CGRect textFrame = UIEdgeInsetsInsetRect(self.bounds, combinedInsets);

  CGFloat placeholderHeight =
      [_placeholderView
          sizeThatFits:CGSizeMake(textFrame.size.width, CGFLOAT_MAX)]
          .height;
  textFrame.size.height = MIN(placeholderHeight, textFrame.size.height);

  _placeholderView.frame = textFrame;

  if (!self.scrollEnabled || !_placeholderView.hidden) {
    CGFloat maxWidth = self.bounds.size.width;
    if (maxWidth > 0) {
      CGSize fittingSize =
          [self sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
      [self notifySizeDidChangeForContentSize:fittingSize];
    }
  }
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
  [super setContentInset:contentInset];
  [self setNeedsLayout];
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset {
  [super setTextContainerInset:textContainerInset];
  [self setNeedsLayout];
}

- (void)scrollSelectionToVisibleWithInsets:(UIEdgeInsets)insets {
  CGRect caretRect = [self caretRectForPosition:self.selectedTextRange.end];

  caretRect = UIEdgeInsetsInsetRect(
      caretRect, UIEdgeInsetsMake(-insets.top, -insets.left, -insets.bottom,
                                  -insets.right));

  [self scrollRectToVisible:caretRect animated:YES];
}

- (void)setContentSize:(CGSize)contentSize {
  [super setContentSize:contentSize];

  [self notifySizeDidChangeForContentSize:contentSize];
}

- (void)notifySizeDidChangeForContentSize:(CGSize)contentSize {
  UIEdgeInsets contentInsets = self.adjustedContentInset;

  UIEdgeInsets combinedInsets =
      UIEdgeInsetsMake(self.textContainerInset.top + contentInsets.top,
                       self.textContainerInset.left + contentInsets.left,
                       self.textContainerInset.bottom + contentInsets.bottom,
                       self.textContainerInset.right + contentInsets.right);
  CGFloat height = MAX(0.0, ceil(contentSize.height - combinedInsets.top -
                                 combinedInsets.bottom));
  CGFloat width = MAX(0.0, ceil(contentSize.width - combinedInsets.left -
                                combinedInsets.right));
  if (!_placeholderView.hidden) {
    CGFloat placeholderMaxWidth = width > 0 ? width
                                            : self.bounds.size.width -
                                                  combinedInsets.left -
                                                  combinedInsets.right;
    if (placeholderMaxWidth > 0) {
      CGSize placeholderSize = [_placeholderView
          sizeThatFits:CGSizeMake(placeholderMaxWidth, CGFLOAT_MAX)];
      height = MAX(height, ceil(placeholderSize.height));
    }
  }
  CGSize newSize = CGSizeMake(width, height);

  if (CGSizeAlmostEqual(newSize, _lastCommittedSize, 0.5)) {
    return;
  }

  _lastCommittedSize = newSize;
  [self.layoutDelegate sizeDidChange:newSize];
}

@end
