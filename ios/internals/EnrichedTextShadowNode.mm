#import "EnrichedTextShadowNode.h"
#import "EnrichedPreparedText.h"
#import "EnrichedTextBuilder.h"
#import <react/utils/ManagedObjectWrapper.h>

#include <react/renderer/core/LayoutConstraints.h>
#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {

extern const char EnrichedTextComponentName[] = "EnrichedText";

const std::shared_ptr<void> &
EnrichedTextShadowNode::prepare(const EnrichedTextKey &key) const {
  if (preparedText_ != nullptr && preparedKey_ == key) {
    return preparedText_;
  }

  const auto &state = getStateData();
  if (state.getPreparedText() != nullptr && state.getKey() == key) {
    preparedText_ = state.getPreparedText();
  } else {
    @autoreleasepool {
      EnrichedPreparedText *preparedText = [EnrichedTextBuilder
          preparedTextWithLabelProps:getConcreteProps()
                  fontSizeMultiplier:key.fontSizeMultiplier];
      preparedText_ = wrapManagedObject(preparedText);
    }
  }

  preparedKey_ = key;
  return preparedText_;
}

Size EnrichedTextShadowNode::measureContent(
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

void EnrichedTextShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();

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
