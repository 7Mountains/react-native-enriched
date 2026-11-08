#pragma once

#include <ReactNativeEnriched/EnrichedTextShadowNode.h>
#include <react/renderer/core/ConcreteComponentDescriptor.h>

namespace facebook::react {

using EnrichedTextComponentDescriptor =
    ConcreteComponentDescriptor<EnrichedTextShadowNode>;

} // namespace facebook::react
