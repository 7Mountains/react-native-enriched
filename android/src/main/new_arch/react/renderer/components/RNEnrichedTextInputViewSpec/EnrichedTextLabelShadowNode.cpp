#include "EnrichedTextLabelShadowNode.h"
#include "conversions.h"

#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {

extern const char EnrichedTextLabelComponentName[] = "EnrichedText";

void EnrichedTextLabelShadowNode::setMeasurementsManager(
    const std::shared_ptr<EnrichedTextMeasurementManager>
        &measurementsManager) {
  ensureUnsealed();
  measurementsManager_ = measurementsManager;
}

const folly::dynamic &EnrichedTextLabelShadowNode::getLayoutProps() const {
  if (layoutProps_.isNull()) {
    layoutProps_ = toDynamic(getConcreteProps());
  }
  return layoutProps_;
}

Size EnrichedTextLabelShadowNode::measureContent(
    const LayoutContext &layoutContext,
    const LayoutConstraints &layoutConstraints) const {
  static const EnrichedTextRef noText;
  const auto &layoutProps = getLayoutProps();
  const auto &state = getStateData();
  const auto *built = hasMeasured_                       ? &measured_
                      : state.layoutProps == layoutProps ? &state.prepared
                                                         : nullptr;
  auto isReusable = built != nullptr && built->isReusable &&
                    built->fits(layoutConstraints.maximumSize.width,
                                layoutContext.pointScaleFactor,
                                layoutContext.fontSizeMultiplier);

  auto measurement = measurementsManager_->measure(
      getSurfaceId(), layoutProps, layoutConstraints,
      isReusable ? built->text : noText);

  measurement.prepared.pointScaleFactor = layoutContext.pointScaleFactor;
  measurement.prepared.fontSizeMultiplier = layoutContext.fontSizeMultiplier;
  measured_ = std::move(measurement.prepared);
  hasMeasured_ = true;

  return layoutConstraints.clamp(measurement.size);
}

void EnrichedTextLabelShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();

  const auto &layoutProps = getLayoutProps();
  const auto &state = getStateData();
  auto size = getLayoutMetrics().getContentFrame().size;

  const auto *prepared = hasMeasured_                       ? &measured_
                         : state.layoutProps == layoutProps ? &state.prepared
                                                            : nullptr;

  if (prepared == nullptr ||
      !prepared->fits(size.width, layoutContext.pointScaleFactor,
                      layoutContext.fontSizeMultiplier)) {
    measureContent(layoutContext,
                   LayoutConstraints{.minimumSize = size, .maximumSize = size});
    prepared = &measured_;
  }

  if (prepared != &state.prepared &&
      (state.layoutProps != layoutProps ||
       !jni::Environment::current()->IsSameObject(state.prepared.text.get(),
                                                  prepared->text.get()))) {
    setStateData(EnrichedTextState{layoutProps, *prepared});
  }

  ConcreteViewShadowNode::layout(layoutContext);
}

} // namespace facebook::react
