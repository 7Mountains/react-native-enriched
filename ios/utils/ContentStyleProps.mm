#import "ContentStyleProps.h"
#import "StringExtension.h"
#import <React/RCTConversions.h>
#import <React/RCTFont.h>

@implementation ContentStyleProps

+ (ContentStyleProps *)fromFolly:(folly::dynamic)folly
                     defaultFont:(UIFont *)defaultFont {
  ContentStyleProps *props = [[ContentStyleProps alloc] init];

  if (folly["backgroundColor"].isNumber()) {
    auto color = facebook::react::SharedColor(
        facebook::react::Color(folly["backgroundColor"].asInt()));
    props.backgroundColor = RCTUIColorFromSharedColor(color);
  } else {
    props.backgroundColor = [UIColor clearColor];
  }

  if (folly["textColor"].isNumber()) {
    auto color = facebook::react::SharedColor(
        facebook::react::Color(folly["textColor"].asInt()));
    props.textColor = RCTUIColorFromSharedColor(color);
  } else {
    props.textColor = [UIColor blackColor];
  }

  if (folly["borderColor"].isNumber()) {
    auto color = facebook::react::SharedColor(
        facebook::react::Color(folly["borderColor"].asInt()));
    props.borderColor = RCTUIColorFromSharedColor(color);
  } else {
    props.borderColor = nil;
  }

  if (folly["borderWidth"].isNumber()) {
    props.borderWidth = folly["borderWidth"].asDouble();
  } else {
    props.borderWidth = 0;
  }

  if (folly["borderStyle"].isString()) {
    props.borderStyle =
        [NSString fromCppString:folly["borderStyle"].asString()];
  } else {
    props.borderStyle = @"solid";
  }

  if (folly["borderRadius"].isNumber()) {
    props.borderRadius = folly["borderRadius"].asDouble();
  } else {
    props.borderRadius = 0;
  }

  if (folly["marginTop"].isNumber()) {
    props.marginTop = folly["marginTop"].asDouble();
  } else {
    props.marginTop = 0;
  }

  if (folly["marginBottom"].isNumber()) {
    props.marginBottom = folly["marginBottom"].asDouble();
  } else {
    props.marginBottom = 0;
  }

  if (folly["marginRight"].isNumber()) {
    props.marginRight = folly["marginRight"].asDouble();
  } else {
    props.marginRight = 0;
  }

  if (folly["marginLeft"].isNumber()) {
    props.marginLeft = folly["marginLeft"].asDouble();
  } else {
    props.marginLeft = 0;
  }

  if (folly["paddingTop"].isNumber()) {
    props.paddingTop = folly["paddingTop"].asDouble();
  } else {
    props.paddingTop = 0;
  }

  if (folly["paddingBottom"].isNumber()) {
    props.paddingBottom = folly["paddingBottom"].asDouble();
  } else {
    props.paddingBottom = 0;
  }

  if (folly["paddingRight"].isNumber()) {
    props.paddingRight = folly["paddingRight"].asDouble();
  } else {
    props.paddingRight = 0;
  }

  if (folly["paddingLeft"].isNumber()) {
    props.paddingLeft = folly["paddingLeft"].asDouble();
  } else {
    props.paddingLeft = 0;
  }

  if (folly["imageWidth"].isNumber()) {
    props.imageWidth = folly["imageWidth"].asDouble();
  } else {
    props.imageWidth = 0;
  }

  if (folly["imageHeight"].isNumber()) {
    props.imageHeight = folly["imageHeight"].asDouble();
  } else {
    props.imageHeight = 0;
  }

  if (folly["imageBorderRadiusTopLeft"].isNumber()) {
    props.imageBorderRadiusTopLeft =
        folly["imageBorderRadiusTopLeft"].asDouble();
  } else {
    props.imageBorderRadiusTopLeft = 0.0;
  }

  if (folly["imageBorderRadiusTopRight"].isNumber()) {
    props.imageBorderRadiusTopRight =
        folly["imageBorderRadiusTopRight"].asDouble();
  } else {
    props.imageBorderRadiusTopRight = 0.0;
  }

  if (folly["imageBorderRadiusBottomLeft"].isNumber()) {
    props.imageBorderRadiusBottomLeft =
        folly["imageBorderRadiusBottomLeft"].asDouble();
  } else {
    props.imageBorderRadiusBottomLeft = 0.0;
  }

  if (folly["imageBorderRadiusTopRight"].isNumber()) {
    props.imageBorderRadiusBottomRight =
        folly["imageBorderRadiusBottomRight"].asDouble();
  } else {
    props.imageBorderRadiusBottomRight = 0.0;
  }

  if (folly["imageResizeMode"].isString()) {
    props.imageResizeMode =
        [NSString fromCppString:folly["imageResizeMode"].asString()];
  } else {
    props.imageResizeMode = @"cover";
  }

  if (folly["fallbackImageURI"].isString()) {
    props.fallbackImageURI =
        [NSString fromCppString:folly["fallbackImageURI"].asString()];
  } else {
    props.fallbackImageURI = nil;
  }

  if (folly["width"].isNumber()) {
    props.width = folly["width"].asDouble();
  } else {
    props.width = 0.0;
  }

  if (folly["height"].isNumber()) {
    props.height = folly["height"].asDouble();
  } else {
    props.height = props.imageHeight > 0 ? props.imageHeight : 50.0;
  }

  NSString *fontWeight =
      folly["fontWeight"].isString()
          ? [NSString fromCppString:folly["fontWeight"].asString()]
          : @"400";

  CGFloat fontSize =
      folly["fontSize"].isNumber() ? folly["fontSize"].asDouble() : 14.0;

  props.font = [RCTFont updateFont:defaultFont
                        withFamily:nil
                              size:@(fontSize)
                            weight:fontWeight
                             style:nil
                           variant:nil
                   scaleMultiplier:1.0];

  return props;
}

+ (NSDictionary *)getSinglePropsFromFollyDynamic:(folly::dynamic)folly
                                     defaultFont:(UIFont *)defaultFont {
  ContentStyleProps *props = [ContentStyleProps fromFolly:folly
                                              defaultFont:defaultFont];
  return @{@"all" : props};
}

+ (NSDictionary *)getComplexPropsFromFollyDynamic:(folly::dynamic)folly
                                      defaultFont:(UIFont *)defaultFont {
  NSMutableDictionary *dict = [NSMutableDictionary new];

  for (const auto &obj : folly.items()) {
    if (obj.first.isString() && obj.second.isObject()) {
      NSString *key = [NSString fromCppString:obj.first.asString()];
      ContentStyleProps *props = [ContentStyleProps fromFolly:obj.second
                                                  defaultFont:defaultFont];
      dict[key] = props;
    }
  }
  return dict;
}

@end
