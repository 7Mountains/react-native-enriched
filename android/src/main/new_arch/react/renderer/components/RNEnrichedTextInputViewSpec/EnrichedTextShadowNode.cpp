#include "EnrichedTextShadowNode.h"

#include <react/renderer/core/LayoutContext.h>

namespace facebook::react {
extern const char EnrichedTextComponentName[] = "EnrichedTextView";

void EnrichedTextShadowNode::setMeasurementsManager(
    const std::shared_ptr<EnrichedTextMeasurementManager>
        &measurementsManager) {
  ensureUnsealed();
  measurementsManager_ = measurementsManager;
}

Size EnrichedTextShadowNode::measureContent(
    const LayoutContext &layoutContext,
    const LayoutConstraints &layoutConstraints) const {
  static const EnrichedTextRef noText;

  const auto &props = getConcreteProps();
  const auto &state = getStateData();

  // The text built for the same props, by this node or the one it's cloned
  // from (e.g. measured again at another width), isn't parsed again
  const auto *built = hasMeasured_               ? &measured_
                      : state.isBuiltFrom(props) ? &state.prepared
                                                 : nullptr;
  auto isReusable =
      built != nullptr && built->fits(layoutConstraints.maximumSize.width,
                                      layoutContext.pointScaleFactor,
                                      layoutContext.fontSizeMultiplier);

  auto measurement =
      measurementsManager_->measure(props, layoutContext, layoutConstraints,
                                    isReusable ? built->text : noText);

  measured_ = std::move(measurement.prepared);
  hasMeasured_ = true;

  return layoutConstraints.clamp(measurement.size);
}

void EnrichedTextShadowNode::layout(LayoutContext layoutContext) {
  ensureUnsealed();

  const auto &props = getConcreteProps();
  const auto &state = getStateData();
  auto size = getLayoutMetrics().getContentFrame().size;

  const auto *prepared = hasMeasured_               ? &measured_
                         : state.isBuiltFrom(props) ? &state.prepared
                                                    : nullptr;

  // Not measured (Yoga knew the size), or measured at another width than
  // the final one: the text is built now for the view, laid out at its width
  if (prepared == nullptr ||
      !prepared->fits(size.width, layoutContext.pointScaleFactor,
                      layoutContext.fontSizeMultiplier)) {
    measureContent(layoutContext,
                   LayoutConstraints{.minimumSize = size, .maximumSize = size});
    prepared = &measured_;
  }

  if (prepared != &state.prepared &&
      (!state.isBuiltFrom(props) ||
       !jni::Environment::current()->IsSameObject(state.prepared.text.get(),
                                                  prepared->text.get()))) {
    setStateData(EnrichedTextState{
        std::static_pointer_cast<const EnrichedTextViewProps>(getProps()),
        *prepared});
  }

  ConcreteViewShadowNode::layout(layoutContext);
}

} // namespace facebook::react
