#import "ContentStyleProps.h"
#import "StringExtension.h"
#import <React/RCTConversions.h>
#import <React/RCTFont.h>

@implementation ContentStyleProps

#pragma mark - Helpers

static folly::dynamic ObjectOrEmpty(folly::dynamic obj, const char *key) {
  return obj[key].isObject() ? obj[key] : folly::dynamic::object();
}

static CGFloat CGFloatFromFolly(folly::dynamic obj, const char *key,
                                CGFloat defaultValue) {
  return obj[key].isNumber() ? obj[key].asDouble() : defaultValue;
}

static BOOL BoolFromFolly(folly::dynamic obj, const char *key,
                          BOOL defaultValue) {
  return obj[key].isBool() ? obj[key].asBool() : defaultValue;
}

static NSString *NSStringFromFolly(folly::dynamic obj, const char *key,
                                   NSString *defaultValue) {
  return obj[key].isString() ? [NSString fromCppString:obj[key].asString()]
                             : defaultValue;
}

static id NSObjectFromFolly(folly::dynamic value) {
  if (value.isNull()) {
    return nil;
  }

  if (value.isBool()) {
    return @(value.asBool());
  }

  if (value.isInt()) {
    return @(value.asInt());
  }

  if (value.isDouble()) {
    return @(value.asDouble());
  }

  if (value.isString()) {
    return [NSString fromCppString:value.asString()];
  }

  if (value.isArray()) {
    NSMutableArray *result = [NSMutableArray new];
    for (const auto &item : value) {
      id converted = NSObjectFromFolly(item);
      if (converted) {
        [result addObject:converted];
      }
    }
    return result;
  }

  if (value.isObject()) {
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (const auto &item : value.items()) {
      if (item.first.isString()) {
        NSString *key = [NSString fromCppString:item.first.asString()];
        id converted = NSObjectFromFolly(item.second);
        if (converted) {
          result[key] = converted;
        }
      }
    }
    return result;
  }

  return nil;
}

static UIColor *UIColorFromFolly(folly::dynamic obj, const char *key,
                                 UIColor *defaultValue) {
  auto value = obj[key];

  if (value.isNull()) {
    return defaultValue;
  }

  if (value.isNumber()) {
    auto color =
        facebook::react::SharedColor(facebook::react::Color(value.asInt()));
    return RCTUIColorFromSharedColor(color);
  }

  id nsValue = NSObjectFromFolly(value);
  if (nsValue) {
    UIColor *color = [RCTConvert UIColor:nsValue];
    return color ?: defaultValue;
  }

  return defaultValue;
}

static UIEdgeInsets EdgeInsetsFromFolly(folly::dynamic obj) {
  return UIEdgeInsetsMake(CGFloatFromFolly(obj, "paddingTop", 0),
                          CGFloatFromFolly(obj, "paddingLeft", 0),
                          CGFloatFromFolly(obj, "paddingBottom", 0),
                          CGFloatFromFolly(obj, "paddingRight", 0));
}

static UIEdgeInsets MarginInsetsFromFolly(folly::dynamic obj) {
  return UIEdgeInsetsMake(CGFloatFromFolly(obj, "marginTop", 0),
                          CGFloatFromFolly(obj, "marginLeft", 0),
                          CGFloatFromFolly(obj, "marginBottom", 0),
                          CGFloatFromFolly(obj, "marginRight", 0));
}

static CGSize SizeFromWidthHeight(folly::dynamic obj) {
  return CGSizeMake(CGFloatFromFolly(obj, "width", 0),
                    CGFloatFromFolly(obj, "height", 0));
}

static EnrichedBorderStyle BorderStyleFromFolly(folly::dynamic obj) {
  NSString *value = NSStringFromFolly(obj, "borderStyle", @"solid");

  if ([value isEqualToString:@"dashed"])
    return EnrichedBorderStyleDashed;
  if ([value isEqualToString:@"dotted"])
    return EnrichedBorderStyleDotted;
  if ([value isEqualToString:@"none"])
    return EnrichedBorderStyleNone;

  return EnrichedBorderStyleSolid;
}

static ContentImageResizeMode ImageResizeModeFromFolly(folly::dynamic obj) {
  NSString *value = NSStringFromFolly(obj, "resizeMode", @"cover");

  if ([value isEqualToString:@"contain"])
    return ContentImageResizeModeContain;
  if ([value isEqualToString:@"stretch"])
    return ContentImageResizeModeStretch;
  return ContentImageResizeModeCover;
}

static UIFont *FontFromFolly(folly::dynamic obj, UIFont *defaultFont,
                             CGFloat defaultSize) {
  NSString *family = NSStringFromFolly(obj, "fontFamily", nil);
  NSString *weight = NSStringFromFolly(obj, "fontWeight", nil);
  CGFloat size = CGFloatFromFolly(obj, "fontSize", defaultSize);
  BOOL bold = BoolFromFolly(obj, "bold", NO);

  NSString *resolvedWeight = weight;
  if (resolvedWeight == nil && bold) {
    resolvedWeight = @"700";
  }

  return [RCTFont updateFont:defaultFont
                  withFamily:family
                        size:@(size)
                      weight:resolvedWeight
                       style:nil
                     variant:nil
             scaleMultiplier:1.0];
}

static NSURL *URLFromFolly(folly::dynamic obj, const char *key) {
  NSString *stringValue = NSStringFromFolly(obj, key, nil);
  if (stringValue.length == 0) {
    return nil;
  }

  return [NSURL URLWithString:stringValue];
}

#pragma mark - Main

+ (instancetype)styleFromDynamic:(folly::dynamic)folly
                     defaultFont:(UIFont *)defaultFont {
  ContentStyleProps *props = [ContentStyleProps new];

  folly::dynamic container = ObjectOrEmpty(folly, "container");
  folly::dynamic title = ObjectOrEmpty(folly, "title");
  folly::dynamic description = ObjectOrEmpty(folly, "description");
  folly::dynamic image = ObjectOrEmpty(folly, "image");
  folly::dynamic imageContainer = ObjectOrEmpty(folly, "imageContainer");
  folly::dynamic textContainer = ObjectOrEmpty(folly, "textContainer");
  folly::dynamic subtitle = ObjectOrEmpty(folly, "subtitle");
  folly::dynamic subDescription = ObjectOrEmpty(folly, "subDescription");

  props.backgroundColor =
      UIColorFromFolly(container, "backgroundColor", UIColor.clearColor);
  props.borderColor = UIColorFromFolly(container, "borderColor", nil);
  props.borderWidth = CGFloatFromFolly(container, "borderWidth", 0);
  props.borderRadius = CGFloatFromFolly(container, "borderRadius", 0);
  props.borderStyle = BorderStyleFromFolly(container);
  props.padding = EdgeInsetsFromFolly(container);
  props.margin = MarginInsetsFromFolly(container);
  props.minHeight = CGFloatFromFolly(container, "minHeight", 0);

  props.textContainerMargin = MarginInsetsFromFolly(textContainer);
  props.textContainerPadding = EdgeInsetsFromFolly(textContainer);

  props.titleColor = UIColorFromFolly(title, "color", UIColor.blackColor);
  props.titleFont = FontFromFolly(title, defaultFont, 14.0);
  CGFloat titleFontSize = CGFloatFromFolly(title, "fontSize", 14.0);
  props.descriptionColor =
      UIColorFromFolly(description, "color", props.textColor);
  props.descriptionFont =
      FontFromFolly(description, defaultFont, titleFontSize);
  props.descriptionColor =
      UIColorFromFolly(description, "color", UIColor.grayColor);

  props.subTitleFont = FontFromFolly(subDescription, defaultFont, 14.0);
  props.subTitleColor = UIColorFromFolly(subtitle, "color", UIColor.blackColor);

  props.subDescriptionFont =
      FontFromFolly(subDescription, defaultFont, titleFontSize);
  props.subdescriptionColor =
      UIColorFromFolly(subDescription, "color", UIColor.grayColor);

  // Image
  props.imageSize = SizeFromWidthHeight(image);
  props.imageResizeMode = ImageResizeModeFromFolly(image);

  // Image container
  props.imageContainerSize = SizeFromWidthHeight(imageContainer);

  // Fallback image
  props.fallbackImageURL = URLFromFolly(folly, "fallbackImageURI");

  return props;
}

#pragma mark - Dictionaries

+ (NSDictionary<NSString *, ContentStyleProps *> *)
    singleStylesFromDynamic:(folly::dynamic)folly
                defaultFont:(UIFont *)defaultFont {
  ContentStyleProps *style = [ContentStyleProps styleFromDynamic:folly
                                                     defaultFont:defaultFont];
  return @{@"all" : style};
}

+ (NSDictionary<NSString *, ContentStyleProps *> *)
    stylesFromDynamicMap:(folly::dynamic)folly
             defaultFont:(UIFont *)defaultFont {
  NSMutableDictionary<NSString *, ContentStyleProps *> *dict =
      [NSMutableDictionary new];

  for (const auto &item : folly.items()) {
    if (item.first.isString() && item.second.isObject()) {
      NSString *key = [NSString fromCppString:item.first.asString()];
      ContentStyleProps *style =
          [ContentStyleProps styleFromDynamic:item.second
                                  defaultFont:defaultFont];
      dict[key] = style;
    }
  }

  return dict;
}

@end
