#import "EnrichedTextParseHost.h"
#import "EnrichedTextStyleFactory.h"
#import "InputConfig.h"

@implementation EnrichedTextParseHost {
  InputConfig *_config;
  NSDictionary<NSAttributedStringKey, id> *_defaultTypingAttributes;
  NSDictionary<NSNumber *, id> *_stylesDict;
}

- (instancetype)initWithConfig:(InputConfig *)config
       defaultTypingAttributes:
           (NSDictionary<NSAttributedStringKey, id> *)defaultTypingAttributes {
  if (self = [super init]) {
    _config = config;
    _defaultTypingAttributes = defaultTypingAttributes;
    // Styles of their own: they cache what they build, and the hosts are
    // used on different threads
    _stylesDict = [EnrichedTextStyleFactory makeStylesWithInput:self];
  }
  return self;
}

+ (instancetype)hostForCurrentThreadWithConfig:(InputConfig *)config
                       defaultTypingAttributes:
                           (NSDictionary<NSAttributedStringKey, id> *)
                               defaultTypingAttributes {
  static NSString *const kParseHostKey = @"EnrichedTextParseHost";
  NSMutableDictionary *threadDictionary =
      NSThread.currentThread.threadDictionary;

  EnrichedTextParseHost *host = threadDictionary[kParseHostKey];
  if (host == nil || host->_config != config ||
      host->_defaultTypingAttributes != defaultTypingAttributes) {
    host =
        [[EnrichedTextParseHost alloc] initWithConfig:config
                              defaultTypingAttributes:defaultTypingAttributes];
    threadDictionary[kParseHostKey] = host;
  }
  return host;
}

- (UITextView *)textView {
  return nil;
}

- (InputConfig *)config {
  return _config;
}

- (NSDictionary<NSAttributedStringKey, id> *)defaultTypingAttributes {
  return _defaultTypingAttributes;
}

- (NSDictionary<NSNumber *, id> *)stylesDict {
  return _stylesDict;
}

- (void)mediaAttachmentDidUpdate:(MediaAttachment *)attachment {
  // No view yet: the one showing the text redraws its attachments
}

@end
