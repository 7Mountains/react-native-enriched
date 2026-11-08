#pragma once

#include "EnrichedTextLabelShadowNode.h"
#include "EnrichedTextMeasurementManager.h"

#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

class EnrichedTextLabelComponentDescriptor final
    : public ConcreteComponentDescriptor<EnrichedTextLabelShadowNode> {
public:
  EnrichedTextLabelComponentDescriptor(
      const ComponentDescriptorParameters &parameters)
      : ConcreteComponentDescriptor(parameters),
        measurementsManager_(std::make_shared<EnrichedTextMeasurementManager>(
            contextContainer_)) {}

  void adopt(ShadowNode &shadowNode) const override {
    ConcreteComponentDescriptor::adopt(shadowNode);
    auto &textShadowNode =
        static_cast<EnrichedTextLabelShadowNode &>(shadowNode);
    textShadowNode.setMeasurementsManager(measurementsManager_);
  }

private:
  const std::shared_ptr<EnrichedTextMeasurementManager> measurementsManager_;
};

} // namespace facebook::react
