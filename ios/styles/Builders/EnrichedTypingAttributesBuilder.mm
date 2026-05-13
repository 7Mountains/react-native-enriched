#import "EnrichedTypingAttributesBuilder.h"
#import "EnrichedParagraphStyle.h"
#import "InputConfig.h"
#import <react/renderer/components/RNEnrichedTextInputViewSpec/Props.h>

@implementation EnrichedTypingAttributesBuilder

+ (NSDictionary<NSAttributedStringKey, id> *)
    buildWithConfig:(InputConfig *)config
              props:(const facebook::react::EnrichedTextInputViewProps &)props {
  NSMutableDictionary<NSAttributedStringKey, id> *attributes =
      [NSMutableDictionary new];

  UIColor *primaryColor = [config primaryColor];
  UIFont *primaryFont = [config primaryFont];

  attributes[NSForegroundColorAttributeName] = primaryColor;
  attributes[NSFontAttributeName] = primaryFont;
  attributes[NSUnderlineColorAttributeName] = primaryColor;
  attributes[NSStrikethroughColorAttributeName] = primaryColor;

  EnrichedParagraphStyle *paragraphStyle = [EnrichedParagraphStyle new];
  paragraphStyle.tailIndent = -0.01;
  paragraphStyle.paragraphSpacing = props.iOSparagraphSpacing;
  paragraphStyle.paragraphSpacingBefore = props.iOSparagraphSpacingBefore;
  paragraphStyle.alignment = NSTextAlignmentNatural;
  paragraphStyle.headingLevel = EnrichedHeadingNone;
  paragraphStyle.minimumLineHeight = config.primaryLineHeight;

  attributes[NSParagraphStyleAttributeName] = paragraphStyle;

  return attributes;
}

@end
