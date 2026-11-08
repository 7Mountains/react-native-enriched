#pragma once

#include "EnrichedTextMeasurementManager.h"
#include "EnrichedTextState.h"

#include <react/renderer/components/RNEnrichedTextInputViewSpec/EventEmitters.h>
#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/components/view/ConcreteViewShadowNode.h>

namespace facebook::react {

JSI_EXPORT extern const char EnrichedTextLabelComponentName[];

class EnrichedTextLabelShadowNode final
    : public ConcreteViewShadowNode<EnrichedTextLabelComponentName,
                                    EnrichedTextProps, EnrichedTextEventEmitter,
                                    EnrichedTextState> {
public:
  using ConcreteViewShadowNode::ConcreteViewShadowNode;

  static ShadowNodeTraits BaseTraits() {
    auto traits = ConcreteViewShadowNode::BaseTraits();
    traits.set(ShadowNodeTraits::Trait::LeafYogaNode);
    traits.set(ShadowNodeTraits::Trait::MeasurableYogaNode);
    return traits;
  }

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
