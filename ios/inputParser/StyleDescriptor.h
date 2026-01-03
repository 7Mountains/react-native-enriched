#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#ifdef __cplusplus
extern "C" {
#endif

using ParamsIMP = NSDictionary *(*)(id, SEL, id);
using CondIMP = BOOL (*)(id, SEL, id, NSRange);
using CondWithAttributesIMP = BOOL (*)(id, SEL, NSDictionary *, NSRange);

struct StyleDescriptor {
  id styleObject;
  NSAttributedStringKey attributeKey;

  const char *tagName;
  const char *subTagName;
  bool selfClosing;

  SEL conditionSEL;
  IMP conditionIMP;

  SEL conditionWithAttributesSEL;
  IMP conditionWithAttributesIMP;

  SEL getParaimsSEL;
  IMP getParamsIMP;
};

inline bool operator==(const StyleDescriptor &a, const StyleDescriptor &b) {
  return &a == &b;
}

#ifdef __cplusplus
}
#endif
