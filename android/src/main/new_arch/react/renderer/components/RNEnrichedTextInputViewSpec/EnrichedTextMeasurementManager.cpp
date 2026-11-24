#include "EnrichedTextMeasurementManager.h"

#include <fbjni/fbjni.h>
#include <react/renderer/core/conversions.h>

using namespace facebook::jni;

namespace facebook::react {

namespace {

struct JEnrichedTextMeasurementResult
    : JavaClass<JEnrichedTextMeasurementResult> {
  static constexpr auto kJavaDescriptor =
      "Lcom/swmansion/enriched/text/EnrichedTextMeasurementResult;";

  jlong size() const {
    static const auto field = javaClassStatic()->getField<jlong>("size");
    return getFieldValue(field);
  }

  local_ref<jobject> text() const {
    static const auto field = javaClassStatic()->getField<jobject>("text");
    return getFieldValue(field);
  }

  jfloat builtWidth() const {
    static const auto field = javaClassStatic()->getField<jfloat>("builtWidth");
    return getFieldValue(field);
  }
};

struct JEnrichedTextMeasurement : JavaClass<JEnrichedTextMeasurement> {
  static constexpr auto kJavaDescriptor =
      "Lcom/swmansion/enriched/text/EnrichedTextMeasurement;";

  static local_ref<JEnrichedTextMeasurementResult::javaobject>
  measure(jstring text, jint htmlStyleId, jfloat fontSize, jfloat lineHeight,
          jstring fontFamily, jstring fontWeight, jstring fontStyle,
          jboolean allowFontScaling, jint numberOfLines, jstring ellipsizeMode,
          jfloat minWidth, jfloat maxWidth, jfloat minHeight, jfloat maxHeight,
          jobject offeredText) {
    static const auto method =
        javaClassStatic()
            ->getStaticMethod<JEnrichedTextMeasurementResult::javaobject(
                jstring, jint, jfloat, jfloat, jstring, jstring, jstring,
                jboolean, jint, jstring, jfloat, jfloat, jfloat, jfloat,
                jobject)>("measure");
    return method(javaClassStatic(), text, htmlStyleId, fontSize, lineHeight,
                  fontFamily, fontWeight, fontStyle, allowFontScaling,
                  numberOfLines, ellipsizeMode, minWidth, maxWidth, minHeight,
                  maxHeight, offeredText);
  }
};

// `null` for an unset (empty) string prop, without creating a Java string
local_ref<JString> toOptionalJString(const std::string &value) {
  return value.empty() ? local_ref<JString>{} : make_jstring(value);
}

} // namespace

EnrichedTextMeasurementManager::Measurement
EnrichedTextMeasurementManager::measure(const EnrichedTextViewProps &props,
                                        LayoutConstraints layoutConstraints,
                                        const EnrichedTextRef &text) const {
  // A text built before is laid out again: its HTML isn't passed to Kotlin
  auto source =
      text.get() != nullptr ? local_ref<JString>{} : make_jstring(props.text);
  auto fontFamily = toOptionalJString(props.fontFamily);
  auto fontWeight = toOptionalJString(props.fontWeight);
  auto fontStyle = toOptionalJString(props.fontStyle);
  auto ellipsizeMode = toOptionalJString(props.ellipsizeMode);

  auto minimumSize = layoutConstraints.minimumSize;
  auto maximumSize = layoutConstraints.maximumSize;

  auto result = JEnrichedTextMeasurement::measure(
      source.get(), props.htmlStyleId, props.fontSize, props.lineHeight,
      fontFamily.get(), fontWeight.get(), fontStyle.get(),
      props.allowFontScaling, props.numberOfLines, ellipsizeMode.get(),
      minimumSize.width, maximumSize.width, minimumSize.height,
      maximumSize.height, text.get());

  return {
      .size = yogaMeassureToSize(result->size()),
      .prepared =
          {
              .text = make_global(result->text()),
              .width = result->builtWidth(),
          },
  };
}

} // namespace facebook::react
