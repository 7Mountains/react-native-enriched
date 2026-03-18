#include "EnrichedTextInputMeasurementManager.h"
#include "conversions.h"

#include <fbjni/fbjni.h>
#include <react/jni/ReadableNativeMap.h>
#include <react/renderer/core/conversions.h>

using namespace facebook::jni;

namespace facebook::react {

Size EnrichedTextInputMeasurementManager::measure(
    SurfaceId surfaceId, int viewTag, const EnrichedTextInputViewProps &props,
    LayoutConstraints layoutConstraints, float stateHeight) const {

  auto minimumSize = layoutConstraints.minimumSize;
  auto maximumSize = layoutConstraints.maximumSize;

  float width = maximumSize.width;

  float height = stateHeight > 0 ? stateHeight : 40.0f;

  width = std::max(minimumSize.width, std::min(width, maximumSize.width));
  height = std::max(minimumSize.height, std::min(height, maximumSize.height));

  return {width, height};
}

} // namespace facebook::react
