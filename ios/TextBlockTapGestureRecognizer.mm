#import "TextBlockTapGestureRecognizer.h"
#import "CheckboxHitTestUtils.h"
#import "EnrichedTextInputView.h"

@implementation TextBlockTapGestureRecognizer {
  TextBlockTapKind _tapKind;
  NSInteger _characterIndex;
  NSTextAttachment *_attachment;
}

- (instancetype)initWithTarget:(id)target
                        action:(SEL)action
                      textView:(UITextView *)textView
                         input:(EnrichedTextInputView *)input {

  self = [super initWithTarget:target action:action];
  if (self) {
    _textView = textView;
    _input = input;

    self.cancelsTouchesInView = YES;
    self.delaysTouchesBegan = YES;
    self.delaysTouchesEnded = YES;
  }
  return self;
}

- (TextBlockTapKind)tapKind {
  return _tapKind;
}
- (NSInteger)characterIndex {
  return _characterIndex;
}
- (NSTextAttachment *)attachment {
  return _attachment;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  _tapKind = TextBlockTapKindNone;
  _characterIndex = NSNotFound;
  _attachment = nil;

  if (!self.textView || !self.input) {
    self.state = UIGestureRecognizerStateFailed;
    return;
  }

  UITouch *touch = touches.anyObject;
  CGPoint point = [touch locationInView:self.textView];
  NSInteger checkboxIndex =
      [CheckboxHitTestUtils hitTestCheckboxAtPoint:point inInput:self.input];

  if (checkboxIndex >= 0) {
    _tapKind = TextBlockTapKindCheckbox;
    _characterIndex = checkboxIndex;
    [super touchesBegan:touches withEvent:event];
    return;
  }

  NSLayoutManager *layoutManager = self.textView.layoutManager;
  NSTextContainer *textContainer = self.textView.textContainer;

  NSUInteger glyphIndex = [layoutManager glyphIndexForPoint:point
                                            inTextContainer:textContainer
                             fractionOfDistanceThroughGlyph:nil];

  if (glyphIndex != NSNotFound) {
    NSUInteger charIndex =
        [layoutManager characterIndexForGlyphAtIndex:glyphIndex];

    if (charIndex < self.textView.textStorage.length &&
        [self.textView.textStorage.string
            characterAtIndex:charIndex] == NSAttachmentCharacter) {

      NSTextAttachment *att =
          [self.textView.textStorage attribute:NSAttachmentAttributeName
                                       atIndex:charIndex
                                effectiveRange:nil];

      if (att) {
        _tapKind = TextBlockTapKindAttachment;
        _characterIndex = charIndex;
        _attachment = att;
        [super touchesBegan:touches withEvent:event];
        return;
      }
    }
  }
  self.state = UIGestureRecognizerStateFailed;
}

@end
