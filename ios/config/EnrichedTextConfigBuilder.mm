#import "EnrichedTextConfigBuilder.h"
#import "ColorExtension.h"
#import "ContentStyleProps.h"
#import "EnrichedImageLoader.h"
#import "InputConfig.h"
#import "MentionStyleProps.h"
#import "StringExtension.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import <React/RCTConversions.h>
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

@implementation EnrichedTextConfigBuilder : NSObject

+ (InputConfig *)
    makeConfigFromProps:
        (const facebook::react::EnrichedTextInputViewProps &)newViewProps
           oldViewProps:
               (const facebook::react::EnrichedTextInputViewProps &)oldViewProps
         previousConfig:(InputConfig *)previousConfig {
  BOOL stylePropChanged = NO;

  BOOL isFirstMount = NO;
  // any style prop changes:
  // firstly we create the new config for the changes
  InputConfig *newConfig;

  if (previousConfig == nullptr) {
    isFirstMount = YES;
    newConfig = [[InputConfig alloc] init];
  } else {
    newConfig = [previousConfig copy];
  }

  if (newViewProps.color != oldViewProps.color) {
    if (isColorMeaningful(newViewProps.color)) {
      UIColor *uiColor = RCTUIColorFromSharedColor(newViewProps.color);
      [newConfig setPrimaryColor:uiColor];
    } else {
      [newConfig setPrimaryColor:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.fontSize != oldViewProps.fontSize) {
    if (newViewProps.fontSize) {
      NSNumber *fontSize = @(newViewProps.fontSize);
      [newConfig setPrimaryFontSize:fontSize];
    } else {
      [newConfig setPrimaryFontSize:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.fontWeight != oldViewProps.fontWeight) {
    if (!newViewProps.fontWeight.empty()) {
      [newConfig
          setPrimaryFontWeight:[NSString
                                   fromCppString:newViewProps.fontWeight]];
    } else {
      [newConfig setPrimaryFontWeight:nullptr];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.fontFamily != oldViewProps.fontFamily) {
    if (!newViewProps.fontFamily.empty()) {
      [newConfig
          setPrimaryFontFamily:[NSString
                                   fromCppString:newViewProps.fontFamily]];
    } else {
      [newConfig setPrimaryFontFamily:nullptr];
    }
    stylePropChanged = YES;
  }

  // rich text style

  if (newViewProps.htmlStyle.h1.fontSize !=
      oldViewProps.htmlStyle.h1.fontSize) {
    [newConfig setH1FontSize:newViewProps.htmlStyle.h1.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h1.bold != oldViewProps.htmlStyle.h1.bold) {
    [newConfig setH1Bold:newViewProps.htmlStyle.h1.bold];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.fontSize !=
      oldViewProps.htmlStyle.h2.fontSize) {
    [newConfig setH2FontSize:newViewProps.htmlStyle.h2.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h2.bold != oldViewProps.htmlStyle.h2.bold) {
    [newConfig setH2Bold:newViewProps.htmlStyle.h2.bold];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.fontSize !=
      oldViewProps.htmlStyle.h3.fontSize) {
    [newConfig setH3FontSize:newViewProps.htmlStyle.h3.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h3.bold != oldViewProps.htmlStyle.h3.bold) {
    [newConfig setH3Bold:newViewProps.htmlStyle.h3.bold];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h4.fontSize !=
      oldViewProps.htmlStyle.h4.fontSize) {
    [newConfig setH4FontSize:newViewProps.htmlStyle.h4.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h4.bold != oldViewProps.htmlStyle.h4.bold) {
    [newConfig setH4Bold:newViewProps.htmlStyle.h4.bold];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h5.fontSize !=
      oldViewProps.htmlStyle.h5.fontSize) {
    [newConfig setH5FontSize:newViewProps.htmlStyle.h5.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h5.bold != oldViewProps.htmlStyle.h5.bold) {
    [newConfig setH5Bold:newViewProps.htmlStyle.h5.bold];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h6.fontSize !=
      oldViewProps.htmlStyle.h6.fontSize) {
    [newConfig setH6FontSize:newViewProps.htmlStyle.h6.fontSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.h6.bold != oldViewProps.htmlStyle.h6.bold) {
    [newConfig setH6Bold:newViewProps.htmlStyle.h6.bold];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.blockquote.borderColor !=
      oldViewProps.htmlStyle.blockquote.borderColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.blockquote.borderColor)) {
      [newConfig setBlockquoteBorderColor:RCTUIColorFromSharedColor(
                                              newViewProps.htmlStyle.blockquote
                                                  .borderColor)];
      stylePropChanged = YES;
    }
  }

  if (newViewProps.htmlStyle.checkbox.uncheckedImage !=
      oldViewProps.htmlStyle.checkbox.uncheckedImage) {
    auto uri = newViewProps.htmlStyle.checkbox.uncheckedImage;
    NSURL *url = [NSURL URLWithString:[NSString fromCppString:uri]];
    [[EnrichedImageLoader shared] loadImage:url
                                 completion:^(UIImage *image) {
                                   if (image != nullptr) {
                                     [newConfig setUncheckedmage:image];
                                   }
                                 }];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.checkbox.checkedImage !=
      oldViewProps.htmlStyle.checkbox.checkedImage) {
    auto uri = newViewProps.htmlStyle.checkbox.checkedImage;
    NSURL *url = [NSURL URLWithString:[NSString fromCppString:uri]];
    [[EnrichedImageLoader shared] loadImage:url
                                 completion:^(UIImage *image) {
                                   if (image != nullptr) {
                                     [newConfig setCheckedImage:image];
                                   }
                                 }];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.checkbox.gapWidth !=
      oldViewProps.htmlStyle.checkbox.gapWidth) {
    [newConfig
        setCheckBoxListGapWidth:newViewProps.htmlStyle.checkbox.gapWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.checkbox.marginLeft !=
      oldViewProps.htmlStyle.checkbox.marginLeft) {
    [newConfig
        setCheckBoxListMarginLeft:newViewProps.htmlStyle.checkbox.marginLeft];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.checkbox.imageWidth !=
      oldViewProps.htmlStyle.checkbox.imageWidth) {
    [newConfig setCheckBoxWidth:newViewProps.htmlStyle.checkbox.imageWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.checkbox.imageHeight !=
      oldViewProps.htmlStyle.checkbox.imageHeight) {
    [newConfig setCheckBoxHeight:newViewProps.htmlStyle.checkbox.imageHeight];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.checkbox.checkedTextColor !=
      oldViewProps.htmlStyle.checkbox.checkedTextColor) {
    [newConfig setCheckedTextColor:RCTUIColorFromSharedColor(
                                       newViewProps.htmlStyle.checkbox
                                           .checkedTextColor)];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.divider.color !=
      oldViewProps.htmlStyle.divider.color) {
    [newConfig setDividerColor:RCTUIColorFromSharedColor(
                                   newViewProps.htmlStyle.divider.color)];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.divider.thickness !=
      oldViewProps.htmlStyle.divider.thickness) {
    [newConfig setDividerThickness:newViewProps.htmlStyle.divider.thickness];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.divider.height !=
      oldViewProps.htmlStyle.divider.height) {
    [newConfig setDividerHeight:newViewProps.htmlStyle.divider.height];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.blockquote.borderWidth !=
      oldViewProps.htmlStyle.blockquote.borderWidth) {
    [newConfig
        setBlockquoteBorderWidth:newViewProps.htmlStyle.blockquote.borderWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.blockquote.gapWidth !=
      oldViewProps.htmlStyle.blockquote.gapWidth) {
    [newConfig
        setBlockquoteGapWidth:newViewProps.htmlStyle.blockquote.gapWidth];
    stylePropChanged = YES;
  }

  // since this prop defaults to undefined on JS side, we need to force set the
  // value on first mount
  if (newViewProps.htmlStyle.blockquote.color !=
          oldViewProps.htmlStyle.blockquote.color ||
      isFirstMount) {
    if (isColorMeaningful(newViewProps.htmlStyle.blockquote.color)) {
      [newConfig
          setBlockquoteColor:RCTUIColorFromSharedColor(
                                 newViewProps.htmlStyle.blockquote.color)];
    } else {
      [newConfig setBlockquoteColor:[newConfig primaryColor]];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.code.color != oldViewProps.htmlStyle.code.color) {
    if (isColorMeaningful(newViewProps.htmlStyle.code.color)) {
      [newConfig setInlineCodeFgColor:RCTUIColorFromSharedColor(
                                          newViewProps.htmlStyle.code.color)];
      stylePropChanged = YES;
    }
  }

  if (newViewProps.htmlStyle.code.backgroundColor !=
      oldViewProps.htmlStyle.code.backgroundColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.code.backgroundColor)) {
      [newConfig setInlineCodeBgColor:RCTUIColorFromSharedColor(
                                          newViewProps.htmlStyle.code
                                              .backgroundColor)];
      stylePropChanged = YES;
    }
  }

  if (newViewProps.htmlStyle.ol.gapWidth !=
      oldViewProps.htmlStyle.ol.gapWidth) {
    [newConfig setOrderedListGapWidth:newViewProps.htmlStyle.ol.gapWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.ol.marginLeft !=
      oldViewProps.htmlStyle.ol.marginLeft) {
    [newConfig setOrderedListMarginLeft:newViewProps.htmlStyle.ol.marginLeft];
    stylePropChanged = YES;
  }

  // since this prop defaults to undefined on JS side, we need to force set the
  // value on first mount
  if (newViewProps.htmlStyle.ol.markerFontWeight !=
          oldViewProps.htmlStyle.ol.markerFontWeight ||
      isFirstMount) {
    if (!newViewProps.htmlStyle.ol.markerFontWeight.empty()) {
      [newConfig
          setOrderedListMarkerFontWeight:
              [NSString
                  fromCppString:newViewProps.htmlStyle.ol.markerFontWeight]];
    } else {
      [newConfig setOrderedListMarkerFontWeight:[newConfig primaryFontWeight]];
    }
    stylePropChanged = YES;
  }

  // since this prop defaults to undefined on JS side, we need to force set the
  // value on first mount
  if (newViewProps.htmlStyle.ol.markerColor !=
          oldViewProps.htmlStyle.ol.markerColor ||
      isFirstMount) {
    if (isColorMeaningful(newViewProps.htmlStyle.ol.markerColor)) {
      [newConfig
          setOrderedListMarkerColor:RCTUIColorFromSharedColor(
                                        newViewProps.htmlStyle.ol.markerColor)];
    } else {
      [newConfig setOrderedListMarkerColor:[newConfig primaryColor]];
    }
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.ul.bulletColor !=
      oldViewProps.htmlStyle.ul.bulletColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.ul.bulletColor)) {
      [newConfig setUnorderedListBulletColor:RCTUIColorFromSharedColor(
                                                 newViewProps.htmlStyle.ul
                                                     .bulletColor)];
      stylePropChanged = YES;
    }
  }

  if (newViewProps.htmlStyle.ul.bulletSize !=
      oldViewProps.htmlStyle.ul.bulletSize) {
    [newConfig setUnorderedListBulletSize:newViewProps.htmlStyle.ul.bulletSize];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.ul.gapWidth !=
      oldViewProps.htmlStyle.ul.gapWidth) {
    [newConfig setUnorderedListGapWidth:newViewProps.htmlStyle.ul.gapWidth];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.ul.marginLeft !=
      oldViewProps.htmlStyle.ul.marginLeft) {
    [newConfig setUnorderedListMarginLeft:newViewProps.htmlStyle.ul.marginLeft];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.a.color != oldViewProps.htmlStyle.a.color) {
    if (isColorMeaningful(newViewProps.htmlStyle.a.color)) {
      [newConfig setLinkColor:RCTUIColorFromSharedColor(
                                  newViewProps.htmlStyle.a.color)];
      stylePropChanged = YES;
    }
  }

  if (newViewProps.htmlStyle.codeblock.color !=
      oldViewProps.htmlStyle.codeblock.color) {
    if (isColorMeaningful(newViewProps.htmlStyle.codeblock.color)) {
      [newConfig
          setCodeBlockFgColor:RCTUIColorFromSharedColor(
                                  newViewProps.htmlStyle.codeblock.color)];
      stylePropChanged = YES;
    }
  }

  if (newViewProps.htmlStyle.codeblock.backgroundColor !=
      oldViewProps.htmlStyle.codeblock.backgroundColor) {
    if (isColorMeaningful(newViewProps.htmlStyle.codeblock.backgroundColor)) {
      [newConfig setCodeBlockBgColor:RCTUIColorFromSharedColor(
                                         newViewProps.htmlStyle.codeblock
                                             .backgroundColor)];
      stylePropChanged = YES;
    }
  }

  if (newViewProps.htmlStyle.codeblock.borderRadius !=
      oldViewProps.htmlStyle.codeblock.borderRadius) {
    [newConfig
        setCodeBlockBorderRadius:newViewProps.htmlStyle.codeblock.borderRadius];
    stylePropChanged = YES;
  }

  if (newViewProps.htmlStyle.a.textDecorationLine !=
      oldViewProps.htmlStyle.a.textDecorationLine) {
    NSString *objcString =
        [NSString fromCppString:newViewProps.htmlStyle.a.textDecorationLine];
    if ([objcString isEqualToString:DecorationUnderline]) {
      [newConfig setLinkDecorationLine:DecorationUnderline];
    } else {
      // both DecorationNone and a different, wrong value gets a DecorationNone
      // here
      [newConfig setLinkDecorationLine:DecorationNone];
    }
    stylePropChanged = YES;
  }

  folly::dynamic oldMentionStyle = oldViewProps.htmlStyle.mention;
  folly::dynamic newMentionStyle = newViewProps.htmlStyle.mention;
  if (oldMentionStyle != newMentionStyle) {
    bool newSingleProps = NO;

    for (const auto &obj : newMentionStyle.items()) {
      if (obj.second.isInt() || obj.second.isString()) {
        // we are in just a single MentionStyleProps object
        newSingleProps = YES;
        break;
      } else if (obj.second.isObject()) {
        // we are in map of indicators to MentionStyleProps
        newSingleProps = NO;
        break;
      }
    }

    if (newSingleProps) {
      [newConfig setMentionStyleProps:
                     [MentionStyleProps
                         getSinglePropsFromFollyDynamic:newMentionStyle]];
    } else {
      [newConfig setMentionStyleProps:
                     [MentionStyleProps
                         getComplexPropsFromFollyDynamic:newMentionStyle]];
    }

    stylePropChanged = YES;
  }

  folly::dynamic oldContentStyle = oldViewProps.htmlStyle.content;
  folly::dynamic newContentStyle = newViewProps.htmlStyle.content;

  if (oldContentStyle != newContentStyle) {
    bool newSingleProps = NO;

    for (const auto &obj : newContentStyle.items()) {
      if (obj.second.isInt() || obj.second.isString()) {
        // we are in just a single MentionStyleProps object
        newSingleProps = YES;
        break;
      } else if (obj.second.isObject()) {
        // we are in map of indicators to MentionStyleProps
        newSingleProps = NO;
        break;
      }
    }

    if (newSingleProps) {
      [newConfig setContentStyleProps:
                     [ContentStyleProps
                         getSinglePropsFromFollyDynamic:newContentStyle
                                            defaultFont:newConfig.primaryFont]];
    } else {
      [newConfig
          setContentStyleProps:
              [ContentStyleProps
                  getComplexPropsFromFollyDynamic:newContentStyle
                                      defaultFont:newConfig.primaryFont]];
    }

    stylePropChanged = YES;
  }

  // mention indicators
  auto mismatchPair = std::mismatch(newViewProps.mentionIndicators.begin(),
                                    newViewProps.mentionIndicators.end(),
                                    oldViewProps.mentionIndicators.begin(),
                                    oldViewProps.mentionIndicators.end());
  if (mismatchPair.first != newViewProps.mentionIndicators.end() ||
      mismatchPair.second != oldViewProps.mentionIndicators.end()) {
    NSMutableSet<NSNumber *> *newIndicators = [[NSMutableSet alloc] init];
    for (const std::string &item : newViewProps.mentionIndicators) {
      if (item.length() == 1) {
        [newIndicators addObject:@(item[0])];
      }
    }
    [newConfig setMentionIndicators:newIndicators];
  }

  return stylePropChanged ? newConfig : previousConfig;
}

@end
