#include "EnrichedTextInputMeasurementManager.h"
#include "conversions.h"

#include <fbjni/fbjni.h>
#include <react/jni/ReadableNativeMap.h>
#include <react/renderer/core/conversions.h>

using namespace facebook::jni;

namespace facebook::react {

// The first layout comes before the view has laid out its text (no height in
// the state yet): its height is measured from the props instead of guessed, so
// the input doesn't mount too tall and then jump to its height
float EnrichedTextInputMeasurementManager::measureInitialHeight(
    SurfaceId surfaceId, int viewTag, const EnrichedTextInputViewProps &props,
    LayoutConstraints layoutConstraints) const {
  const jni::global_ref<jobject> &fabricUIManager =
      contextContainer_->at<jni::global_ref<jobject>>("FabricUIManager");

  static const auto measure =
      facebook::jni::findClassStatic(
          "com/facebook/react/fabric/FabricUIManager")
          ->getMethod<jlong(jint, jstring, ReadableMap::javaobject,
                            ReadableMap::javaobject, ReadableMap::javaobject,
                            jfloat, jfloat, jfloat, jfloat)>("measure");

  local_ref<JString> componentName = make_jstring("EnrichedTextInputView");

  folly::dynamic extraData = folly::dynamic::object();
  extraData["viewTag"] = viewTag;
  local_ref<ReadableNativeMap::javaobject> extraDataRNM =
      ReadableNativeMap::newObjectCxxArgs(extraData);
  local_ref<ReadableMap::javaobject> extraDataRM =
      make_local(reinterpret_cast<ReadableMap::javaobject>(extraDataRNM.get()));

  auto serializedProps = toDynamic(props);
  local_ref<ReadableNativeMap::javaobject> propsRNM =
      ReadableNativeMap::newObjectCxxArgs(serializedProps);
  local_ref<ReadableMap::javaobject> propsRM =
      make_local(reinterpret_cast<ReadableMap::javaobject>(propsRNM.get()));

  auto minimumSize = layoutConstraints.minimumSize;
  auto maximumSize = layoutConstraints.maximumSize;

  auto measurement = yogaMeassureToSize(
      measure(fabricUIManager, surfaceId, componentName.get(),
              extraDataRM.get(), propsRM.get(), nullptr, minimumSize.width,
              maximumSize.width, minimumSize.height, maximumSize.height));

  return measurement.height;
}

Size EnrichedTextInputMeasurementManager::measure(
    SurfaceId surfaceId, int viewTag, const EnrichedTextInputViewProps &props,
    LayoutConstraints layoutConstraints, float stateHeight) const {

  auto minimumSize = layoutConstraints.minimumSize;
  auto maximumSize = layoutConstraints.maximumSize;

  float width = maximumSize.width;

  float height =
      stateHeight > 0
          ? stateHeight
          : measureInitialHeight(surfaceId, viewTag, props, layoutConstraints);

  width = std::max(minimumSize.width, std::min(width, maximumSize.width));
  height = std::max(minimumSize.height, std::min(height, maximumSize.height));

  return {width, height};
}

} // namespace facebook::react
