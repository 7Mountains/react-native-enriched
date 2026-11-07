#pragma once
#include <ReactNativeEnriched/EnrichedTextViewShadowNode.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

using EnrichedTextViewComponentDescriptor =
    ConcreteComponentDescriptor<EnrichedTextViewShadowNode>;

} // namespace facebook::react
