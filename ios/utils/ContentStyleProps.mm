#import "ContentStyleProps.h"
#import <React/RCTConversions.h>
#import "StringExtension.h"

@implementation ContentStyleProps

+ (ContentStyleProps *)fromFolly:(folly::dynamic)folly {
    ContentStyleProps *props = [[ContentStyleProps alloc] init];

    if (folly["backgroundColor"].isNumber()) {
        auto color = facebook::react::SharedColor(facebook::react::Color(folly["backgroundColor"].asInt()));
        props.backgroundColor = RCTUIColorFromSharedColor(color);
    } else {
        props.backgroundColor = [UIColor clearColor];
    }

    if (folly["textColor"].isNumber()) {
        auto color = facebook::react::SharedColor(facebook::react::Color(folly["textColor"].asInt()));
        props.textColor = RCTUIColorFromSharedColor(color);
    } else {
        props.textColor = [UIColor blackColor];
    }

    if (folly["borderColor"].isNumber()) {
        auto color = facebook::react::SharedColor(facebook::react::Color(folly["borderColor"].asInt()));
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
        props.borderStyle = [NSString fromCppString:folly["borderStyle"].asString()];
    } else {
        props.borderStyle = @"solid";
    }

    if (folly["borderRadius"].isNumber()) {
        props.borderRadius = folly["borderRadius"].asDouble();
    } else {
        props.borderRadius = 0;
    }
    
    if(folly["marginTop"].isNumber()) {
      props.marginTop = folly["marginTop"].asDouble();
    } else {
      props.marginTop = 0;
    }

    if(folly["marginBottom"].isNumber()) {
      props.marginBottom = folly["marginBottom"].asDouble();
    } else {
      props.marginBottom = 0;
    }
    
    if(folly["marginRight"].isNumber()) {
      props.marginRight = folly["marginRight"].asDouble();
    } else {
      props.marginRight = 0;
    }
    
    if(folly["marginLeft"].isNumber()) {
      props.marginLeft = folly["marginLeft"].asDouble();
    } else {
      props.marginLeft = 0;
    }
  
    if(folly["paddingTop"].isNumber()) {
      props.paddingTop = folly["paddingTop"].asDouble();
    } else {
      props.paddingTop = 0;
    }

    if(folly["paddingBottom"].isNumber()) {
      props.paddingBottom = folly["paddingBottom"].asDouble();
    } else {
      props.paddingBottom = 0;
    }
    
    if(folly["paddingRight"].isNumber()) {
      props.paddingRight = folly["paddingRight"].asDouble();
    } else {
      props.paddingRight = 0;
    }
    
    if(folly["paddingLeft"].isNumber()) {
      props.paddingLeft = folly["paddingLeft"].asDouble();
    } else {
      props.paddingLeft = 0;
    }
  
    if(folly["imageWidth"].isNumber()) {
      props.imageWidth = folly["imageWidth"].asDouble();
    } else {
      props.imageWidth = 0;
    }
      
    if(folly["imageHeight"].isNumber()) {
      props.imageHeight = folly["imageHeight"].asDouble();
    } else {
      props.imageHeight = 0;
    }
    
    if(folly["imageBorderRadiusTopLeft"].isNumber()) {
      props.imageBorderRadiusTopLeft = folly["imageBorderRadiusTopLeft"].asDouble();
    } else {
      props.imageBorderRadiusTopLeft = 0.0;
    }

    if(folly["imageBorderRadiusTopRight"].isNumber()) {
      props.imageBorderRadiusTopRight = folly["imageBorderRadiusTopRight"].asDouble();
    } else {
      props.imageBorderRadiusTopRight = 0.0;
    }
  
    if(folly["imageBorderRadiusBottomLeft"].isNumber()) {
      props.imageBorderRadiusBottomLeft = folly["imageBorderRadiusBottomLeft"].asDouble();
    } else {
      props.imageBorderRadiusBottomLeft = 0.0;
    }
    
    if(folly["imageBorderRadiusTopRight"].isNumber()) {
      props.imageBorderRadiusBottomRight = folly["imageBorderRadiusBottomRight"].asDouble();
    } else {
      props.imageBorderRadiusBottomRight = 0.0;
    }
    
    if(folly["placeholderImageURI"].isString()) {
      props.placeholderImageURI = [NSString fromCppString: folly["placeholderImageURI"].asString()];
    } else {
      props.placeholderImageURI = nil;
    }
  
    if(folly["imageResizeMode"].isString()) {
      props.imageResizeMode = [NSString fromCppString: folly["imageResizeMode"].asString()];
    } else {
      props.imageResizeMode = @"cover";
    }
  
    if(folly["fontSize"].isNumber()) {
      props.fontSize =  folly["fontSize"].asDouble();
    } else {
      props.fontSize = 14.0;
    }
  
    if(folly["fontWeight"].isString()) {
      props.fontWeight = [NSString fromCppString:folly["fontWeight"].asString()];
    } else {
      props.fontWeight = @"500";
    }
  
    return props;
}

+ (NSDictionary *)getSinglePropsFromFollyDynamic:(folly::dynamic)folly {
    ContentStyleProps *props = [ContentStyleProps fromFolly:folly];
    return @{@"all": props};
}

+ (NSDictionary *)getComplexPropsFromFollyDynamic:(folly::dynamic)folly {
    NSMutableDictionary *dict = [NSMutableDictionary new];

    for (const auto& obj : folly.items()) {
        if (obj.first.isString() && obj.second.isObject()) {
            NSString *key = [NSString fromCppString:obj.first.asString()];
            ContentStyleProps *props = [ContentStyleProps fromFolly:obj.second];
            dict[key] = props;
        }
    }
    return dict;
}

@end
