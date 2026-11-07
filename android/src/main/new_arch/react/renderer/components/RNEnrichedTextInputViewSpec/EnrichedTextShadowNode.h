#pragma once

#include "EnrichedTextMeasurementManager.h"
#include "EnrichedTextState.h"

#include <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextComponentName[];

/*
 * `ShadowNode` for <EnrichedTextView>: a leaf measured by its text. The text
 * built by the measurement, for the final width, goes to the view through the
 * state, as the prepared layout of React Native's <Text>: the view shows it
 * as it's mounted, without parsing the HTML.
 */
class EnrichedTextShadowNode final
    : public ConcreteViewShadowNode<
          EnrichedTextComponentName, EnrichedTextViewProps,
          EnrichedTextViewEventEmitter, EnrichedTextState> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

  // Associates a shared `EnrichedTextMeasurementManager` with the node.
  void
  setMeasurementsManager(const std::shared_ptr<EnrichedTextMeasurementManager>
                             &measurementsManager);

  Size
  measureContent(const LayoutContext &layoutContext,
                 const LayoutConstraints &layoutConstraints) const override;

  void layout(LayoutContext layoutContext) override;

private:
  const folly::dynamic &getLayoutProps() const;

  std::shared_ptr<EnrichedTextMeasurementManager> measurementsManager_;

  mutable folly::dynamic layoutProps_;
  mutable bool hasMeasured_{false};
  mutable EnrichedPreparedText measured_;
};
} // namespace facebook::react
