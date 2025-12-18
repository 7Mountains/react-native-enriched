#import "TextBlockTapGestureRecognizer.h"
#import "CheckboxHitTestUtils.h"
#import "EnrichedTextInputView.h"

@implementation TextBlockTapGestureRecognizer {
  TextBlockTapKind _tapKind;
  NSInteger _characterIndex;
  NSTextAttachment *_attachment;
}

- (TextBlockTapKind)tapKind { return _tapKind; }
- (NSInteger)characterIndex { return _characterIndex; }
- (NSTextAttachment *)attachment { return _attachment; }

- (void)touchesBegan:(NSSet<UITouch *> *)touches
           withEvent:(UIEvent *)event
{
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
      [CheckboxHitTestUtils hitTestCheckboxAtPoint:point
                                           inInput:self.input];

  if (checkboxIndex >= 0) {
    _tapKind = TextBlockTapKindCheckbox;
    _characterIndex = checkboxIndex;
    [super touchesBegan:touches withEvent:event];
    return;
  }

  NSLayoutManager *lm = self.textView.layoutManager;
  NSTextContainer *tc = self.textView.textContainer;

  NSUInteger glyphIndex =
      [lm glyphIndexForPoint:point
              inTextContainer:tc
       fractionOfDistanceThroughGlyph:nil];

  if (glyphIndex != NSNotFound) {
    NSUInteger charIndex = [lm characterIndexForGlyphAtIndex:glyphIndex];

    if (charIndex < self.textView.textStorage.length &&
        [self.textView.textStorage.string characterAtIndex:charIndex] ==
            NSAttachmentCharacter) {

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
