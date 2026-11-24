#import "EnrichedParserStyleRegistry.h"

#include <cstring>
#include <string>
#include <utility>
#include <vector>

static NSMapTable<NSDictionary *, EnrichedParserStyleRegistry *> *
Registries(void) {
  static NSMapTable *registries;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    registries = [[NSMapTable alloc]
        initWithKeyOptions:NSPointerFunctionsWeakMemory |
                           NSPointerFunctionsObjectPointerPersonality
              valueOptions:NSPointerFunctionsStrongMemory
                  capacity:8];
  });
  return registries;
}

@implementation EnrichedParserStyleRegistry {
  std::vector<std::pair<std::string, id<BaseStyleProtocol>>> _tagStyles;
}

+ (instancetype)registryForStyles:
    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles {
  NSMapTable *registries = Registries();

  if (styles != nil) {
    @synchronized(registries) {
      EnrichedParserStyleRegistry *registry = [registries objectForKey:styles];
      if (registry != nil) {
        return registry;
      }
    }
  }

  EnrichedParserStyleRegistry *registry =
      [[EnrichedParserStyleRegistry alloc] initWithStyles:styles];

  if (styles != nil) {
    @synchronized(registries) {
      [registries setObject:registry forKey:styles];
    }
  }

  return registry;
}

- (instancetype)initWithStyles:
    (NSDictionary<NSNumber *, id<BaseStyleProtocol>> *)styles {
  if (!(self = [super init]))
    return nil;

  NSMutableDictionary *tags = [NSMutableDictionary dictionary];
  NSMutableArray<id> *paragraphModifiers = [NSMutableArray new];

  [styles enumerateKeysAndObjectsUsingBlock:^(
              NSNumber *key, id<BaseStyleProtocol> style, BOOL *stop) {
    const char *tagName = [[style class] tagName];
    if (!tagName && [style.class isParagraphStyle]) {
      [paragraphModifiers addObject:style];
    }
    if (tagName) {
      NSString *tag = [NSString stringWithUTF8String:tagName];
      tags[tag] = style;
    }
  }];

  for (NSString *tag in tags) {
    _tagStyles.emplace_back(tag.UTF8String, tags[tag]);
  }

  _paragraphModifiers = paragraphModifiers.copy;

  return self;
}

- (id<BaseStyleProtocol>)styleForTag:(const char *)tag {
  if (tag == nullptr) {
    return nil;
  }
  for (const auto &entry : _tagStyles) {
    if (strcmp(entry.first.c_str(), tag) == 0) {
      return entry.second;
    }
  }
  return nil;
}

@end
