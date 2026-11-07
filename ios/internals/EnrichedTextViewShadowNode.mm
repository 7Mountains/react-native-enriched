#import "EnrichedTextViewShadowNode.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextBuilder.h"
#import <react/utils/ManagedObjectWrapper.h>

#include <react/renderer/core/LayoutConstraints.h>
#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {

extern const char EnrichedTextViewComponentName[] = "EnrichedTextView";

const std::shared_ptr<void> &
EnrichedTextViewShadowNode::prepare(const EnrichedTextKey &key) const {
  if (preparedText_ != nullptr && preparedKey_ == key) {
    return preparedText_;
  }

  const auto &state = getStateData();

  if (state.getPreparedText() != nullptr && state.getKey() == key) {
    preparedText_ = state.getPreparedText();
  } else {
    @autoreleasepool {
      EnrichedPreparedText *preparedText =
          [EnrichedTextBuilder preparedTextWithProps:getConcreteProps()
                                  fontSizeMultiplier:key.fontSizeMultiplier];
      preparedText_ = wrapManagedObject(preparedText);
    }
  }

  preparedKey_ = key;
  return preparedText_;
}

Size EnrichedTextViewShadowNode::measureContent(
    const LayoutContext &layoutContext,
    const LayoutConstraints &layoutConstraints) const {
  const auto &props = getConcreteProps();
  auto key =
      EnrichedTextKey::fromProps(props, layoutContext.fontSizeMultiplier);

  EnrichedPreparedText *preparedText =
      (EnrichedPreparedText *)unwrapManagedObject(prepare(key));

  CGSize size =
      [EnrichedTextBuilder sizeOfText:preparedText.text
                   constrainedToWidth:layoutConstraints.maximumSize.width
                 maximumNumberOfLines:props.numberOfLines
                        lineBreakMode:EnrichedNSLineBreakModeFromEllipsizeMode(
                                          props.ellipsizeMode)];

  return layoutConstraints.clamp({size.width, size.height});
}

void EnrichedTextViewShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();

  // Measured, or not (Yoga knew the size): the view gets the text either way
  auto key = EnrichedTextKey::fromProps(getConcreteProps(),
                                        layoutContext.fontSizeMultiplier);
  const auto &preparedText = prepare(key);
  const auto &state = getStateData();

  if (state.getPreparedText() != preparedText || state.getKey() != key) {
    setStateData(EnrichedTextViewState{key, preparedText});
  }

  ConcreteViewShadowNode::layout(layoutContext);
}

} // namespace facebook::react
