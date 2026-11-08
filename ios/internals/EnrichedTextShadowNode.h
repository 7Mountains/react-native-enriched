#pragma once

#include <ReactNativeEnriched/EnrichedTextViewState.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

#include <optional>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextComponentName[];

class EnrichedTextShadowNode final
    : public ConcreteViewShadowNode<EnrichedTextComponentName,
                                    EnrichedTextProps, EnrichedTextEventEmitter,
                                    EnrichedTextViewState> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

  Size
  measureContent(const LayoutContext &layoutContext,
                 const LayoutConstraints &layoutConstraints) const override;

  void layout(LayoutContext layoutContext) override;

private:
  const std::shared_ptr<void> &prepare(const EnrichedTextKey &key) const;

  mutable std::shared_ptr<void> preparedText_;
  mutable std::optional<EnrichedTextKey> preparedKey_;
};

} // namespace facebook::react
