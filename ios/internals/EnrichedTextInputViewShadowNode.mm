#import "EnrichedTextInputViewShadowNode.h"

#import <React/RCTShadowView+Layout.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>

namespace facebook::react {

extern const char EnrichedTextInputViewComponentName[] =
    "EnrichedTextInputView";

void EnrichedTextInputViewShadowNode::createTextStorage() const {
  if (_textStorage) {
    return;
  }

  _textContainer = [NSTextContainer new];
  _textContainer.lineFragmentPadding = 0;
  _textContainer.maximumNumberOfLines = 0;

  _layoutManager = [NSLayoutManager new];
  [_layoutManager addTextContainer:_textContainer];

  _textStorage = [NSTextStorage new];
  [_textStorage addLayoutManager:_layoutManager];
  _prevAttributedText = [NSAttributedString alloc];
}

void EnrichedTextInputViewShadowNode::dirtyLayoutIfNeeded() {
  const auto state = this->getStateData();
  if (![_prevAttributedText
          isEqualToAttributedString:state.getAttributedText()]) {
    YGNodeMarkDirty(&yogaNode_);
  }
}

EnrichedTextInputViewShadowNode::EnrichedTextInputViewShadowNode(
    const ShadowNodeFragment &fragment, const ShadowNodeFamily::Shared &family,
    ShadowNodeTraits traits)
    : ConcreteViewShadowNode(fragment, family, traits) {
  createTextStorage();
}

EnrichedTextInputViewShadowNode::EnrichedTextInputViewShadowNode(
    const ShadowNode &sourceShadowNode, const ShadowNodeFragment &fragment)
    : ConcreteViewShadowNode(sourceShadowNode, fragment) {
  dirtyLayoutIfNeeded();
}

NSAttributedString *
EnrichedTextInputViewShadowNode::getAttributedString() const {
  NSAttributedString *attributedText = getStateData().getAttributedText();

  if (!attributedText || attributedText.length == 0) {
    // Fallback to a measurable placeholder
    return [[NSAttributedString alloc] initWithString:@"I"];
  }

  return attributedText;
}

Size EnrichedTextInputViewShadowNode::measureContent(
    const LayoutContext &, const LayoutConstraints &constraints) const {

  createTextStorage();

  NSAttributedString *attributedText = getAttributedString();
  _prevAttributedText = attributedText;

  CGSize maxSize = {constraints.maximumSize.width,
                    constraints.maximumSize.height ==
                            std::numeric_limits<Float>::infinity()
                        ? CGFLOAT_MAX
                        : constraints.maximumSize.height};

  _textContainer.size = maxSize;

  [_textStorage replaceCharactersInRange:NSMakeRange(0, +_textStorage.length)
                    withAttributedString:attributedText];

  [_layoutManager ensureLayoutForTextContainer:_textContainer];

  CGSize usedSize =
      [_layoutManager usedRectForTextContainer:_textContainer].size;

  auto width = std::min((Float)usedSize.width, constraints.maximumSize.width);
  auto height =
      std::min((Float)usedSize.height, constraints.maximumSize.height);

  return Size(width, height);
}

} // namespace facebook::react
