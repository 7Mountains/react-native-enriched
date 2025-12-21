#import "EnrichedTextInputViewShadowNode.h"

#import <React/RCTShadowView+Layout.h>
#import <react/utils/ManagedObjectWrapper.h>
#import <yoga/Yoga.h>

namespace facebook::react {

extern const char EnrichedTextInputViewComponentName[] =
    "EnrichedTextInputView";

void EnrichedTextInputViewShadowNode::createTextStorage() const {
  if (textStorage_) {
    return;
  }

  textContainer_ = [NSTextContainer new];
  textContainer_.lineFragmentPadding = 0;
  textContainer_.maximumNumberOfLines = 0;

  layoutManager_ = [NSLayoutManager new];
  [layoutManager_ addTextContainer:textContainer_];

  textStorage_ = [NSTextStorage new];
  [textStorage_ addLayoutManager:layoutManager_];
  prevAttributedText_ = [NSAttributedString alloc];
}

void EnrichedTextInputViewShadowNode::dirtyLayoutIfNeeded() {
  const auto state = this->getStateData();
  if (![prevAttributedText_
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

  CGSize maxSize = {constraints.maximumSize.width,
                    constraints.maximumSize.height ==
                            std::numeric_limits<Float>::infinity()
                        ? CGFLOAT_MAX
                        : constraints.maximumSize.height};

  textContainer_.size = maxSize;

  [textStorage_ replaceCharactersInRange:NSMakeRange(0, textStorage_.length)
                    withAttributedString:attributedText];

  [layoutManager_ ensureLayoutForTextContainer:textContainer_];

  CGSize usedSize =
      [layoutManager_ usedRectForTextContainer:textContainer_].size;

  auto width = std::min((Float)usedSize.width, constraints.maximumSize.width);
  auto height =
      std::min((Float)usedSize.height, constraints.maximumSize.height);

  return Size(width, height);
}

} // namespace facebook::react
