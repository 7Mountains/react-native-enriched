#include "EnrichedTextMeasurementManager.h"
#include "EnrichedTextShadowNode.h"

#include <fbjni/fbjni.h>
#include <react/jni/ReadableNativeMap.h>
#include <react/renderer/core/conversions.h>

using namespace facebook::jni;

namespace facebook::react {

namespace {

struct JEnrichedTextHandoff : JavaClass<JEnrichedTextHandoff> {
  static constexpr auto kJavaDescriptor =
      "Lcom/swmansion/enriched/text/EnrichedTextHandoff;";

  static void offer(jobject text) {
    static const auto method =
        javaClassStatic()->getStaticMethod<void(jobject)>("offer");
    method(javaClassStatic(), text);
  }

  static float builtWidth() {
    static const auto method =
        javaClassStatic()->getStaticMethod<jfloat()>("builtWidth");
    return method(javaClassStatic());
  }

  static bool isBuiltReusable() {
    static const auto method =
        javaClassStatic()->getStaticMethod<jboolean()>("isBuiltReusable");
    return method(javaClassStatic());
  }

  static local_ref<jobject> take() {
    static const auto method =
        javaClassStatic()->getStaticMethod<jobject()>("take");
    return method(javaClassStatic());
  }
};

} // namespace

EnrichedTextMeasurementManager::Measurement
EnrichedTextMeasurementManager::measure(SurfaceId surfaceId,
                                        const folly::dynamic &layoutProps,
                                        LayoutConstraints layoutConstraints,
                                        const EnrichedTextRef &text) const {
  const global_ref<jobject> &fabricUIManager =
      contextContainer_->at<global_ref<jobject>>("FabricUIManager");

  static const auto measure =
      findClassStatic("com/facebook/react/fabric/FabricUIManager")
          ->getMethod<jlong(jint, jstring, ReadableMap::javaobject,
                            ReadableMap::javaobject, ReadableMap::javaobject,
                            jfloat, jfloat, jfloat, jfloat)>("measure");

  local_ref<JString> componentName = make_jstring(EnrichedTextComponentName);

  local_ref<ReadableNativeMap::javaobject> propsRNM =
      ReadableNativeMap::newObjectCxxArgs(layoutProps);
  local_ref<ReadableMap::javaobject> propsRM =
      make_local(reinterpret_cast<ReadableMap::javaobject>(propsRNM.get()));

  auto minimumSize = layoutConstraints.minimumSize;
  auto maximumSize = layoutConstraints.maximumSize;

  // The measurement runs synchronously on this thread, between `offer` and
  // `take`
  JEnrichedTextHandoff::offer(text.get());

  jlong packedSize = 0;
  try {
    packedSize =
        measure(fabricUIManager, surfaceId, componentName.get(), nullptr,
                propsRM.get(), nullptr, minimumSize.width, maximumSize.width,
                minimumSize.height, maximumSize.height);
  } catch (...) {
    JEnrichedTextHandoff::take();
    throw;
  }

  auto width = JEnrichedTextHandoff::builtWidth();
  auto isReusable = JEnrichedTextHandoff::isBuiltReusable();

  return {
      .size = yogaMeassureToSize(packedSize),
      .prepared =
          {
              .text = make_global(JEnrichedTextHandoff::take()),
              .width = width,
              .isReusable = isReusable,
          },
  };
}

} // namespace facebook::react
