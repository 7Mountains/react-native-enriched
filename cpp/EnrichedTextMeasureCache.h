#pragma once

#include <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>
#include <react/renderer/core/LayoutConstraints.h>

#include <cstddef>
#include <functional>
#include <iterator>
#include <list>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <utility>

namespace facebook::react {

// What the measurement of a text depends on besides its props
struct EnrichedTextMeasureContext {
  LayoutConstraints layoutConstraints;
  Float pointScaleFactor;
  Float fontSizeMultiplier;
};

// The measurements of the texts of <EnrichedTextView> made last, shared by the
// shadow nodes (as React Native's text measure cache): a text shown again by
// a new node, e.g. scrolled back to in a list, isn't measured again. Read and
// written on any thread
template <typename Value> class EnrichedTextMeasureCache {
public:
  std::optional<Value> get(const EnrichedTextViewProps &props,
                           const EnrichedTextMeasureContext &context) {
    size_t hash = hashOf(props, context);

    std::lock_guard<std::mutex> lock(mutex_);
    auto entry = find(hash, props, context);
    if (entry == entries_.end()) {
      return std::nullopt;
    }

    entries_.splice(entries_.begin(), entries_, entry);
    return entry->value;
  }

  void set(const EnrichedTextViewProps &props,
           const EnrichedTextMeasureContext &context, Value value) {
    if (props.text.size() > kMaxEntryTextBytes) {
      return;
    }

    size_t hash = hashOf(props, context);

    std::lock_guard<std::mutex> lock(mutex_);
    auto existing = find(hash, props, context);
    if (existing != entries_.end()) {
      existing->value = std::move(value);
      entries_.splice(entries_.begin(), entries_, existing);
      return;
    }

    entries_.push_front(Entry{
        .hash = hash,
        .text = props.text,
        .htmlStyleId = props.htmlStyleId,
        .fontSize = props.fontSize,
        .lineHeight = props.lineHeight,
        .fontFamily = props.fontFamily,
        .fontWeight = props.fontWeight,
        .fontStyle = props.fontStyle,
        .allowFontScaling = props.allowFontScaling,
        .numberOfLines = props.numberOfLines,
        .ellipsizeMode = props.ellipsizeMode,
        .context = context,
        .value = std::move(value),
    });
    index_.emplace(hash, entries_.begin());
    textBytes_ += props.text.size();

    while (entries_.size() > kMaxEntries || textBytes_ > kMaxTextBytes) {
      erase(std::prev(entries_.end()));
    }
  }

  void clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    entries_.clear();
    index_.clear();
    textBytes_ = 0;
  }

private:
  static constexpr size_t kMaxEntries = 512;
  // The html of the entries is kept as their key: a few long texts don't take
  // the memory of many short ones
  static constexpr size_t kMaxTextBytes = 1024 * 1024;
  static constexpr size_t kMaxEntryTextBytes = 32 * 1024;

  // The props the text is laid out by: not its color
  struct Entry {
    size_t hash;
    std::string text;
    int htmlStyleId;
    Float fontSize;
    Float lineHeight;
    std::string fontFamily;
    std::string fontWeight;
    std::string fontStyle;
    bool allowFontScaling;
    int numberOfLines;
    std::string ellipsizeMode;
    EnrichedTextMeasureContext context;
    Value value;

    bool matches(const EnrichedTextViewProps &props,
                 const EnrichedTextMeasureContext &otherContext) const {
      return context.layoutConstraints == otherContext.layoutConstraints &&
             context.pointScaleFactor == otherContext.pointScaleFactor &&
             context.fontSizeMultiplier == otherContext.fontSizeMultiplier &&
             htmlStyleId == props.htmlStyleId && fontSize == props.fontSize &&
             lineHeight == props.lineHeight &&
             allowFontScaling == props.allowFontScaling &&
             numberOfLines == props.numberOfLines &&
             ellipsizeMode == props.ellipsizeMode &&
             fontFamily == props.fontFamily && fontWeight == props.fontWeight &&
             fontStyle == props.fontStyle && text == props.text;
    }
  };

  using Entries = std::list<Entry>;

  static size_t combineHash(size_t seed, size_t value) {
    return seed ^ (value + 0x9e3779b97f4a7c15ULL + (seed << 6) + (seed >> 2));
  }

  static size_t hashOf(const EnrichedTextViewProps &props,
                       const EnrichedTextMeasureContext &context) {
    size_t hash = std::hash<std::string>{}(props.text);
    hash = combineHash(hash, std::hash<int>{}(props.htmlStyleId));
    hash = combineHash(hash, std::hash<Float>{}(props.fontSize));
    hash = combineHash(hash, std::hash<int>{}(props.numberOfLines));
    hash = combineHash(
        hash, std::hash<LayoutConstraints>{}(context.layoutConstraints));
    hash = combineHash(hash, std::hash<Float>{}(context.fontSizeMultiplier));
    return hash;
  }

  typename Entries::iterator find(size_t hash,
                                  const EnrichedTextViewProps &props,
                                  const EnrichedTextMeasureContext &context) {
    auto range = index_.equal_range(hash);
    for (auto it = range.first; it != range.second; ++it) {
      if (it->second->matches(props, context)) {
        return it->second;
      }
    }
    return entries_.end();
  }

  void erase(typename Entries::iterator entry) {
    auto range = index_.equal_range(entry->hash);
    for (auto it = range.first; it != range.second; ++it) {
      if (it->second == entry) {
        index_.erase(it);
        break;
      }
    }
    textBytes_ -= entry->text.size();
    entries_.erase(entry);
  }

  std::mutex mutex_;
  Entries entries_;
  std::unordered_multimap<size_t, typename Entries::iterator> index_;
  size_t textBytes_ = 0;
};

} // namespace facebook::react
