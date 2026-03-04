#import "MDFStyleProps.h"
#import "StringExtension.h"
#import <React/RCTConversions.h>
#import <React/RCTFont.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

using namespace facebook::react;

@implementation MDFStyleProps

- (instancetype)initWithStruct:
    (const EnrichedTextInputViewHtmlStyleMdfStruct &)mdf {

  self = [super init];
  if (!self)
    return nil;

  _height = mdf.height;
  _imageUri = [NSString fromCppString:mdf.imageUri.c_str()];

  _borderRadius = mdf.borderRadius;
  _borderWidth = mdf.borderWidth;

  _stripeWidth = mdf.stripeWidth;

  if (mdf.borderColor) {
    _borderColor = RCTUIColorFromSharedColor(mdf.borderColor);
  }

  CGFloat fontSize = mdf.fontSize ?: 14.0;
  NSString *fontWeight =
      mdf.fontWeight.empty() ? @"500" : [NSString fromCppString:mdf.fontWeight];
  UIFont *defaultFont = [UIFont systemFontOfSize:fontSize];
  _font = [RCTFont updateFont:defaultFont
                   withFamily:nil
                         size:@(fontSize)
                       weight:fontWeight
                        style:nil
                      variant:nil
              scaleMultiplier:1.0];

  _marginLeft = mdf.marginLeft;
  _marginRight = mdf.marginRight;
  _marginTop = mdf.marginTop;
  _marginBottom = mdf.marginBottom;

  _paddingTop = mdf.paddingTop;
  _paddingLeft = mdf.paddingLeft;
  _paddingRight = mdf.paddingRight;
  _paddingBottom = mdf.paddingBottom;

  if (mdf.textColor) {
    _textColor = RCTUIColorFromSharedColor(mdf.textColor);
  } else {
    _textColor = UIColor.blackColor;
  }

  if (mdf.backgroundColor) {
    _backgroundColor = RCTUIColorFromSharedColor(mdf.backgroundColor);
  }

  if (mdf.imageHeight) {
    _imageHeight = mdf.imageHeight;
  } else {
    _imageHeight = 0.0;
  }

  if (mdf.imageWidth) {
    _imageWidth = mdf.imageWidth;
  } else {
    _imageWidth = 0.0;
  }

  if (mdf.imageBorderRadius) {
    _imageBorderRadius = mdf.imageBorderRadius;
  } else {
    _imageBorderRadius = 0.0;
  }

  _imageContainerHeight = mdf.imageContainerHeight;
  _imageContainerWidth = mdf.imageContainerWidth;

  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  MDFStyleProps *copy = [[[self class] allocWithZone:zone] init];

  copy->_height = _height;
  copy->_imageUri = [_imageUri copy];

  copy->_borderRadius = _borderRadius;
  copy->_borderWidth = _borderWidth;

  copy->_borderColor = _borderColor;

  copy->_font = [_font copy];

  copy->_stripeWidth = _stripeWidth;

  copy->_marginLeft = _marginLeft;
  copy->_marginRight = _marginRight;
  copy->_marginTop = _marginTop;
  copy->_marginBottom = _marginBottom;

  copy->_paddingLeft = _paddingLeft;
  copy->_paddingRight = _paddingRight;
  copy->_paddingTop = _paddingTop;
  copy->_paddingBottom = _paddingBottom;

  copy->_textColor = _textColor;
  copy->_backgroundColor = _backgroundColor;

  copy->_imageWidth = _imageWidth;
  copy->_imageHeight = _imageHeight;
  copy->_imageBorderRadius = _imageBorderRadius;

  copy->_imageContainerWidth = _imageContainerWidth;
  copy->_imageContainerHeight = _imageContainerHeight;

  return copy;
}

@end
