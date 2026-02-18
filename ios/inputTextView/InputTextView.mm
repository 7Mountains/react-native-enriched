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

@implementation InputTextView {
  UILabel *_placeholderView;
  CGSize _lastCommittedSize;
};

- (instancetype)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    _placeholderView = [[UILabel alloc] initWithFrame:self.bounds];
    _placeholderView.isAccessibilityElement = NO;
    _placeholderView.numberOfLines = 0;
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

- (void)setPlaceholderText:(NSString *)newPlaceholderText
                attributes:(NSDictionary *)attributes {
  _placeholderText = newPlaceholderText;
  BOOL hasPlaceholder = newPlaceholderText && newPlaceholderText.length > 0;
  NSString *placeholderText = hasPlaceholder ? newPlaceholderText : @"";
  NSMutableDictionary *attributesCopy = [attributes mutableCopy];
  attributesCopy[NSForegroundColorAttributeName] = _placeholderColor;
  attributesCopy[NSUnderlineColorAttributeName] = _placeholderColor;
  attributesCopy[NSStrikethroughColorAttributeName] = _placeholderColor;
  _placeholderView.attributedText =
      [[NSAttributedString alloc] initWithString:placeholderText
                                      attributes:attributes];
  [self setNeedsLayout];
}

- (void)setTypingAttributes:
    (NSDictionary<NSAttributedStringKey, id> *)typingAttributes {
  [super setTypingAttributes:typingAttributes];
  if (self.textStorage.length == 0) {
    [self refreshPlaceholder];
  }
}

- (void)refreshPlaceholder {
  NSMutableDictionary *attributes = [self.typingAttributes mutableCopy];

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
      [_placeholderView sizeThatFits:textFrame.size].height;
  textFrame.size.height = MIN(placeholderHeight, textFrame.size.height);

  _placeholderView.frame = textFrame;

  CGRect usedRect =
      [self.layoutManager usedRectForTextContainer:self.textContainer];
  CGSize newSize = usedRect.size;

  if (CGSizeAlmostEqual(newSize, _lastCommittedSize, 0.5)) {
    return;
  }

  _lastCommittedSize = newSize;
  [self.layoutDelegate sizeDidChange:newSize];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
  [super setContentInset:contentInset];
  [self setNeedsLayout];
}

- (void)setTextContainerInset:(UIEdgeInsets)textContainerInset {
  [super setTextContainerInset:textContainerInset];
  [self setNeedsLayout];
}

@end
