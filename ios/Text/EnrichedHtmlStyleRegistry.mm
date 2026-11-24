#include "EnrichedHtmlStyleRegistry.h"

#include <react/renderer/core/PropsParserContext.h>
#include <react/renderer/core/RawValue.h>
#include <react/utils/ContextContainer.h>

#include <mutex>
#include <unordered_map>

namespace facebook::react {

namespace {

using Styles = std::unordered_map<
    int, std::shared_ptr<const EnrichedTextInputViewHtmlStyleStruct>>;

std::mutex stylesMutex;
int lastId = 0;

Styles &styles() {
  // Never destroyed: read by the shadow nodes until the app exits
  static auto *styles = new Styles();
  return *styles;
}

} // namespace

int EnrichedHtmlStyleRegistry::registerStyle(const folly::dynamic &style) {
  auto parsed = std::make_shared<EnrichedTextInputViewHtmlStyleStruct>();
  if (style.isObject()) {
    ContextContainer contextContainer;
    PropsParserContext context{-1, contextContainer};
    fromRawValue(context, RawValue(style), *parsed);
  }

  std::lock_guard<std::mutex> lock(stylesMutex);
  styles()[++lastId] = std::move(parsed);
  return lastId;
}

std::shared_ptr<const EnrichedTextInputViewHtmlStyleStruct>
EnrichedHtmlStyleRegistry::get(int id) {
  std::lock_guard<std::mutex> lock(stylesMutex);
  auto style = styles().find(id);
  return style != styles().end() ? style->second : nullptr;
}

} // namespace facebook::react
