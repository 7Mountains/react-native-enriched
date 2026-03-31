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

  _minHeight = mdf.container.minHeight;

  _borderRadius = mdf.container.borderRadius;
  _borderWidth = mdf.container.borderWidth;
  _borderLeftWidth = mdf.container.borderLeftWidth;

  _margin =
      UIEdgeInsetsMake(mdf.container.marginTop, mdf.container.marginLeft,
                       mdf.container.marginBottom, mdf.container.marginRight);

  _padding =
      UIEdgeInsetsMake(mdf.container.paddingTop, mdf.container.paddingLeft,
                       mdf.container.paddingBottom, mdf.container.paddingRight);

  _textContainerMargin = UIEdgeInsetsMake(
      mdf.textContainer.marginTop, mdf.textContainer.marginLeft,
      mdf.textContainer.marginBottom, mdf.textContainer.marginRight);

  _textContainerPadding = UIEdgeInsetsMake(
      mdf.textContainer.paddingTop, mdf.textContainer.paddingLeft,
      mdf.textContainer.paddingBottom, mdf.textContainer.paddingRight);

  _backgroundColor =
      mdf.container.backgroundColor
          ? RCTUIColorFromSharedColor(mdf.container.backgroundColor)
          : UIColor.clearColor;

  if (mdf.container.borderColor) {
    _borderColor = RCTUIColorFromSharedColor(mdf.container.borderColor);
  }

  CGFloat fontSize = mdf.title.fontSize ?: 14.0;

  NSString *fontFamily = mdf.title.fontFamily.empty()
                             ? nil
                             : [NSString fromCppString:mdf.title.fontFamily];

  NSString *fontWeight = mdf.title.fontWeight.empty()
                             ? @"400"
                             : [NSString fromCppString:mdf.title.fontWeight];

  UIFont *defaultFont = [UIFont systemFontOfSize:fontSize];

  _font = [RCTFont updateFont:defaultFont
                   withFamily:fontFamily
                         size:@(fontSize)
                       weight:fontWeight
                        style:nil
                      variant:nil
              scaleMultiplier:1.0];

  _textColor = mdf.title.color ? RCTUIColorFromSharedColor(mdf.title.color)
                               : UIColor.blackColor;

  if (!mdf.imageUri.empty()) {
    NSString *uri = [NSString fromCppString:mdf.imageUri];
    _imageURL = [NSURL URLWithString:uri];
  }

  _imageSize = CGSizeMake(mdf.image.width, mdf.image.height);

  _imageContainerSize =
      CGSizeMake(mdf.imageContainer.width, mdf.imageContainer.height);

  _imageContainerBorderRadius = mdf.imageContainer.borderRadius;

  return self;
}

#pragma mark - Copy

- (id)copyWithZone:(NSZone *)zone {
  MDFStyleProps *copy = [[[self class] allocWithZone:zone] init];

  copy->_minHeight = _minHeight;

  copy->_imageURL = [_imageURL copy];

  copy->_borderRadius = _borderRadius;
  copy->_borderWidth = _borderWidth;
  copy->_borderLeftWidth = _borderLeftWidth;

  copy->_borderColor = _borderColor;
  copy->_backgroundColor = _backgroundColor;

  copy->_font = _font; // UIFont immutable
  copy->_textColor = _textColor;

  copy->_margin = _margin;
  copy->_padding = _padding;

  copy->_textContainerMargin = _textContainerMargin;
  copy->_textContainerPadding = _textContainerPadding;

  copy->_imageSize = _imageSize;
  copy->_imageContainerSize = _imageContainerSize;
  copy->_imageContainerBorderRadius = _imageContainerBorderRadius;

  return copy;
}

@end
