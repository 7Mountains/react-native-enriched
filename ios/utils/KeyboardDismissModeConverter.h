static inline UIScrollViewKeyboardDismissMode
KeyboardDismissModeFromString(const std::string &value) {
  if (value == "none") {
    return UIScrollViewKeyboardDismissModeNone;
  }
  if (value == "on-drag") {
    return UIScrollViewKeyboardDismissModeOnDrag;
  }
  if (value == "interactive") {
    return UIScrollViewKeyboardDismissModeInteractive;
  }

  // default
  return UIScrollViewKeyboardDismissModeNone;
}
