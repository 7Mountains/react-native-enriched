#pragma once
#include <ReactNativeEnriched/EnrichedTextViewState.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

#include <optional>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextViewComponentName[];

/*
 * `ShadowNode` for <EnrichedTextView>: a leaf measured by its text. The text
 * built by the measurement goes to the view through the state, as the
 * prepared layout of React Native's <Text>: the view shows it as it's
 * mounted, without parsing the HTML.
 */
class EnrichedTextViewShadowNode final
    : public ConcreteViewShadowNode<
          EnrichedTextViewComponentName, EnrichedTextViewProps,
          EnrichedTextViewEventEmitter, EnrichedTextViewState> {
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
  // The text of the key: built once per node, or taken from the state of the
  // node it's cloned from
  const std::shared_ptr<void> &prepare(const EnrichedTextKey &key) const;

  mutable std::shared_ptr<void> preparedText_;
  mutable std::optional<EnrichedTextKey> preparedKey_;
};

} // namespace facebook::react
