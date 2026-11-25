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

  jboolean isShareable() const {
    static const auto field =
        javaClassStatic()->getField<jboolean>("isShareable");
    return getFieldValue(field);
  }
};

struct JEnrichedTextMeasurement : JavaClass<JEnrichedTextMeasurement> {
  static constexpr auto kJavaDescriptor =
      "Lcom/swmansion/enriched/text/EnrichedTextMeasurement;";

  static local_ref<JEnrichedTextMeasurementResult::javaobject>
  measure(jstring text, jint htmlStyleId, jfloat fontSize, jfloat lineHeight,
          jstring fontFamily, jint fontWeight, jint fontStyle,
          jboolean allowFontScaling, jint numberOfLines, jint ellipsizeMode,
          jfloat minWidth, jfloat maxWidth, jfloat minHeight, jfloat maxHeight,
          jobject offeredText) {
    static const auto method =
        javaClassStatic()
            ->getStaticMethod<JEnrichedTextMeasurementResult::javaobject(
                jstring, jint, jfloat, jfloat, jstring, jint, jint, jboolean,
                jint, jint, jfloat, jfloat, jfloat, jfloat, jobject)>(
                "measure");
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

// `ReactConstants.UNSET`
constexpr jint kUnset = -1;

// As `ReactTypefaceUtils.parseFontWeight`: parsed here, without a Java string
jint toFontWeight(const std::string &value) {
  if (value == "normal") {
    return 400;
  }
  if (value == "bold") {
    return 700;
  }
  if (value.size() == 3 && value[0] >= '1' && value[0] <= '9' &&
      value[1] == '0' && value[2] == '0') {
    return (value[0] - '0') * 100;
  }
  return kUnset;
}

// As `ReactTypefaceUtils.parseFontStyle`: `Typeface.ITALIC` and `NORMAL`
jint toFontStyle(const std::string &value) {
  if (value == "italic") {
    return 2;
  }
  if (value == "normal") {
    return 0;
  }
  return kUnset;
}

// The codes `EnrichedTextMeasurement.toEllipsizeMode` reads, 0 when unset
jint toEllipsizeMode(const std::string &value) {
  if (value == "head") {
    return 1;
  }
  if (value == "middle") {
    return 2;
  }
  if (value == "tail") {
    return 3;
  }
  if (value == "clip") {
    return 4;
  }
  return 0;
}

} // namespace

EnrichedTextMeasurementManager::Measurement
EnrichedTextMeasurementManager::measure(const EnrichedTextViewProps &props,
                                        const LayoutContext &layoutContext,
                                        LayoutConstraints layoutConstraints,
                                        const EnrichedTextRef &text) const {
  EnrichedTextMeasureContext context{
      .layoutConstraints = layoutConstraints,
      .pointScaleFactor = layoutContext.pointScaleFactor,
      .fontSizeMultiplier = layoutContext.fontSizeMultiplier,
  };

  // Measured before, e.g. by another node: neither built nor laid out here
  if (auto measurement = cache_.get(props, context)) {
    return std::move(*measurement);
  }

  bool isShareable = false;
  auto measurement = measureText(props, layoutConstraints, text, &isShareable);
  measurement.prepared.pointScaleFactor = layoutContext.pointScaleFactor;
  measurement.prepared.fontSizeMultiplier = layoutContext.fontSizeMultiplier;

  if (isShareable) {
    cache_.set(props, context, measurement);
  }
  return measurement;
}

EnrichedTextMeasurementManager::Measurement
EnrichedTextMeasurementManager::measureText(const EnrichedTextViewProps &props,
                                            LayoutConstraints layoutConstraints,
                                            const EnrichedTextRef &text,
                                            bool *isShareable) const {
  // A text built before is laid out again: its HTML isn't passed to Kotlin
  auto source =
      text.get() != nullptr ? local_ref<JString>{} : make_jstring(props.text);
  auto fontFamily = toOptionalJString(props.fontFamily);

  auto minimumSize = layoutConstraints.minimumSize;
  auto maximumSize = layoutConstraints.maximumSize;

  auto result = JEnrichedTextMeasurement::measure(
      source.get(), props.htmlStyleId, props.fontSize, props.lineHeight,
      fontFamily.get(), toFontWeight(props.fontWeight),
      toFontStyle(props.fontStyle), props.allowFontScaling, props.numberOfLines,
      toEllipsizeMode(props.ellipsizeMode), minimumSize.width,
      maximumSize.width, minimumSize.height, maximumSize.height, text.get());

  *isShareable = result->isShareable();
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
