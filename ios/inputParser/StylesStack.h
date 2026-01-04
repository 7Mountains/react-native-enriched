#pragma once

#import "StyleHeaders.h"
#import <Foundation/Foundation.h>

#include <vector>

struct StyleContext {
  id<BaseStyleProtocol> style;
  NSRange range;
  NSDictionary *attributes;

  StyleContext(id<BaseStyleProtocol> s, NSRange r, NSDictionary *attrs)
      : style(s), range(r), attributes(attrs ?: @{}) {}
};

struct ActiveStyleEntry {
  id<BaseStyleProtocol> style;
  NSDictionary *attributes;

  ActiveStyleEntry(id<BaseStyleProtocol> s, NSDictionary *attrs)
      : style(s), attributes(attrs ?: @{}) {}
};

class StyleStack {
public:
  StyleStack() { _active.reserve(8); }

  StyleStack(const StyleStack &) = delete;
  StyleStack &operator=(const StyleStack &) = delete;

  inline void push(id<BaseStyleProtocol> style, NSDictionary *attributes) {
    if (!style)
      return;
    _active.emplace_back(style, attributes);
  }

  inline void pop(id<BaseStyleProtocol> style) {
    if (!style)
      return;

    for (auto it = _active.rbegin(); it != _active.rend(); ++it) {
      if (it->style == style) {
        _active.erase(std::next(it).base());
        return;
      }
    }
  }

  inline void applyActiveStyles(std::vector<StyleContext> &out,
                                NSRange range) const {
    if (range.length == 0 || _active.empty())
      return;

    for (const ActiveStyleEntry &e : _active) {
      out.emplace_back(e.style, range, e.attributes);
    }
  }

  inline bool empty() const { return _active.empty(); }

private:
  std::vector<ActiveStyleEntry> _active;
};
