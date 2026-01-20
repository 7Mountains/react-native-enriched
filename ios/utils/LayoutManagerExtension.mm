#import "LayoutManagerExtension.h"
#import "ColorExtension.h"
#import "EnrichedTextInputView.h"
#import "ParagraphsUtils.h"
#import "StyleHeaders.h"
#import <objc/runtime.h>

@implementation NSLayoutManager (LayoutManagerExtension)

static void const *kInputKey = &kInputKey;

#pragma mark - Helpers

static NSRange NormalizeEmptyParagraph(NSRange range, NSUInteger textLength) {
  if (range.length == 0 && range.location < textLength) {
    return NSMakeRange(range.location, 1);
  }
  return range;
}

#pragma mark - Associated input

- (id)input {
  return objc_getAssociatedObject(self, kInputKey);
}

- (void)setInput:(id)value {
  objc_setAssociatedObject(self, kInputKey, value,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Swizzle

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class myClass = [NSLayoutManager class];
    SEL originalSelector = @selector(drawBackgroundForGlyphRange:atPoint:);
    SEL swizzledSelector = @selector(my_drawBackgroundForGlyphRange:atPoint:);

    Method originalMethod = class_getInstanceMethod(myClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(myClass, swizzledSelector);

    method_exchangeImplementations(originalMethod, swizzledMethod);
  });
}

#pragma mark - Entry point

- (void)my_drawBackgroundForGlyphRange:(NSRange)glyphRange
                               atPoint:(CGPoint)origin {
  [self my_drawBackgroundForGlyphRange:glyphRange atPoint:origin];

  EnrichedTextInputView *input = (EnrichedTextInputView *)self.input;
  if (!input)
    return;

  NSRange visibleCharRange = [self characterRangeForGlyphRange:glyphRange
                                              actualGlyphRange:nil];

  [self drawBlockQuotes:input origin:origin visibleCharRange:visibleCharRange];
  [self drawLists:input origin:origin visibleCharRange:visibleCharRange];
  [self drawCodeBlocks:input origin:origin visibleCharRange:visibleCharRange];
  [self drawChecklists:input origin:origin visibleCharRange:visibleCharRange];
}

#pragma mark - Code blocks

- (void)drawCodeBlocks:(EnrichedTextInputView *)input
                origin:(CGPoint)origin
      visibleCharRange:(NSRange)visibleCharRange {

  CodeBlockStyle *style = input->stylesDict[@([CodeBlockStyle getStyleType])];
  if (!style)
    return;

  NSArray<StylePair *> *blocks = [style findAllOccurences:visibleCharRange];
  NSArray<StylePair *> *merged = [self mergeContiguousStylePairs:blocks];

  UIColor *bg =
      [[input->config codeBlockBgColor] colorWithAlphaIfNotTransparent:0.4];
  CGFloat radius = [input->config codeBlockBorderRadius];
  [bg setFill];

  NSUInteger textLength = input->textView.textStorage.length;

  for (StylePair *pair in merged) {
    NSRange blockRange =
        NormalizeEmptyParagraph(pair.rangeValue.rangeValue, textLength);

    NSArray *paragraphs =
        [ParagraphsUtils getSeparateParagraphsRangesIn:input->textView
                                                 range:blockRange];

    for (NSValue *p in paragraphs) {
      NSRange paragraph = NormalizeEmptyParagraph(p.rangeValue, textLength);

      NSRange glyphRange = [self glyphRangeForCharacterRange:paragraph
                                        actualCharacterRange:nil];

      __block BOOL isFirstLine = YES;

      [self
          enumerateLineFragmentsForGlyphRange:glyphRange
                                   usingBlock:^(CGRect rect, CGRect usedRect,
                                                NSTextContainer *container,
                                                NSRange lineGlyphRange,
                                                BOOL *stop) {
                                     CGRect r = rect;
                                     r.origin.x = origin.x;
                                     r.origin.y += origin.y;
                                     r.size.width = container.size.width;

                                     UIRectCorner corners = 0;

                                     if (isFirstLine) {
                                       corners |= UIRectCornerTopLeft |
                                                  UIRectCornerTopRight;
                                     }

                                     if (NSMaxRange(lineGlyphRange) >=
                                         NSMaxRange(glyphRange)) {
                                       corners |= UIRectCornerBottomLeft |
                                                  UIRectCornerBottomRight;
                                     }

                                     UIBezierPath *path = [UIBezierPath
                                         bezierPathWithRoundedRect:r
                                                 byRoundingCorners:corners
                                                       cornerRadii:CGSizeMake(
                                                                       radius,
                                                                       radius)];
                                     [path fill];

                                     isFirstLine = NO;
                                   }];
    }
  }
}

#pragma mark - Block quotes

- (void)drawBlockQuotes:(EnrichedTextInputView *)input
                 origin:(CGPoint)origin
       visibleCharRange:(NSRange)visibleCharRange {

  BlockQuoteStyle *style =
      (BlockQuoteStyle *)input->stylesDict[@([BlockQuoteStyle getStyleType])];
  if (!style)
    return;

  NSString *text = input->textView.textStorage.string;
  NSUInteger textLength = text.length;
  CGFloat gap = input->config.blockquoteGapWidth;

  [text
      enumerateSubstringsInRange:visibleCharRange
                         options:NSStringEnumerationByParagraphs
                      usingBlock:^(NSString *substring, NSRange paragraphRange,
                                   NSRange enclosingRange, BOOL *stop) {
                        NSRange safeRange =
                            NormalizeEmptyParagraph(paragraphRange, textLength);

                        NSDictionary *attrs = [input->textView.textStorage
                            attributesAtIndex:safeRange.location
                               effectiveRange:nil];

                        id value = attrs[[BlockQuoteStyle attributeKey]];
                        if (![style styleCondition:value
                                             range:NSMakeRange(
                                                       safeRange.location, 1)])
                          return;

                        NSRange glyphRange =
                            [self glyphRangeForCharacterRange:safeRange
                                         actualCharacterRange:nil];

                        NSDictionary *drawAttrs = @{
                          NSForegroundColorAttributeName :
                              input->config.blockquoteBorderColor
                        };

                        __block BOOL isFirstLine = YES;

                        [self
                            enumerateLineFragmentsForGlyphRange:glyphRange
                                                     usingBlock:^(
                                                         CGRect rect,
                                                         CGRect usedRect,
                                                         NSTextContainer
                                                             *container,
                                                         NSRange lineGlyphRange,
                                                         BOOL *stop) {
                                                       CGFloat y =
                                                           origin.y +
                                                           rect.origin.y;
                                                       CGFloat textLeft =
                                                           origin.x +
                                                           rect.origin.x +
                                                           usedRect.origin.x;
                                                       CGFloat textRight =
                                                           textLeft +
                                                           usedRect.size.width;

                                                       if (isFirstLine) {
                                                         [@"“" drawAtPoint:
                                                                   CGPointMake(
                                                                       textLeft -
                                                                           gap *
                                                                               2,
                                                                       y)
                                                             withAttributes:
                                                                 drawAttrs];
                                                         isFirstLine = NO;
                                                       }

                                                       if (NSMaxRange(
                                                               lineGlyphRange) >=
                                                           NSMaxRange(
                                                               glyphRange)) {
                                                         [@"”" drawAtPoint:
                                                                   CGPointMake(
                                                                       textRight +
                                                                           gap,
                                                                       y)
                                                             withAttributes:
                                                                 drawAttrs];
                                                       }
                                                     }];
                      }];
}

#pragma mark - Lists
- (void)drawLists:(EnrichedTextInputView *)input
              origin:(CGPoint)origin
    visibleCharRange:(NSRange)visibleCharRange {

  UnorderedListStyle *ul =
      input->stylesDict[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *ol = input->stylesDict[@([OrderedListStyle getStyleType])];

  if (!ul && !ol)
    return;

  NSMutableArray<StylePair *> *pairs = [[NSMutableArray alloc] init];
  if (ul)
    [pairs addObjectsFromArray:[ul findAllOccurences:visibleCharRange]];
  if (ol)
    [pairs addObjectsFromArray:[ol findAllOccurences:visibleCharRange]];

  NSTextStorage *textStorage = input->textView.textStorage;
  NSUInteger textLength = textStorage.length;

  for (StylePair *pair in pairs) {
    NSArray<NSValue *> *paragraphs = [ParagraphsUtils
        getSeparateParagraphsRangesIn:input->textView
                                range:[pair.rangeValue rangeValue]];

    for (NSValue *paragraph in paragraphs) {
      NSRange paragraphRange = [paragraph rangeValue];

      NSParagraphStyle *pStyle =
          [textStorage attribute:NSParagraphStyleAttributeName
                         atIndex:paragraphRange.location
                  effectiveRange:nil];

      if (!pStyle || pStyle.textLists.count == 0) {
        continue;
      }

      NSTextList *list = pStyle.textLists.firstObject;

      NSRange glyphSourceRange = paragraphRange;
      if (glyphSourceRange.length == 0 &&
          glyphSourceRange.location < textLength) {
        glyphSourceRange.length = 1;
      }

      NSRange paragraphGlyphRange =
          [self glyphRangeForCharacterRange:glyphSourceRange
                       actualCharacterRange:nil];

      __block BOOL didDrawMarker = NO;

      [self
          enumerateLineFragmentsForGlyphRange:paragraphGlyphRange
                                   usingBlock:^(CGRect rect, CGRect usedRect,
                                                NSTextContainer *container,
                                                NSRange lineGlyphRange,
                                                BOOL *stop) {
                                     if (didDrawMarker) {
                                       *stop = YES;
                                       return;
                                     }
                                     CGFloat baseY = origin.y + rect.origin.y;

                                     CGFloat indentWidth =
                                         pStyle.firstLineHeadIndent;

                                     CGFloat baseX = origin.x;

                                     if ([list.markerFormat
                                             isEqualToString:
                                                 NSTextListMarkerDisc]) {

                                       CGFloat bulletSize =
                                           [input->config
                                                   unorderedListBulletSize];

                                       CGFloat bulletX =
                                           baseX + indentWidth / 2.0;

                                       CGFloat bulletY =
                                           origin.y + CGRectGetMidY(rect);

                                       CGContextRef ctx =
                                           UIGraphicsGetCurrentContext();
                                       CGContextSaveGState(ctx);
                                       [[input->config unorderedListBulletColor]
                                           setFill];
                                       CGContextAddArc(ctx, bulletX, bulletY,
                                                       bulletSize / 2.0, 0,
                                                       2 * M_PI, YES);
                                       CGContextFillPath(ctx);
                                       CGContextRestoreGState(ctx);

                                     } else {
                                       NSString *marker = [self
                                           markerForList:list
                                               charIndex:
                                                   [self
                                                       characterIndexForGlyphAtIndex:
                                                           lineGlyphRange
                                                               .location]
                                                   input:input];

                                       NSDictionary *markerAttributes = @{
                                         NSFontAttributeName :
                                             [input->config
                                                     orderedListMarkerFont],
                                         NSForegroundColorAttributeName :
                                             [input->config
                                                     orderedListMarkerColor]
                                       };

                                       CGFloat markerWidth =
                                           [marker sizeWithAttributes:
                                                       markerAttributes]
                                               .width;

                                       CGFloat gap =
                                           [input->config orderedListGapWidth];

                                       CGFloat markerX = baseX + indentWidth -
                                                         markerWidth - gap;

                                       [marker drawAtPoint:CGPointMake(markerX,
                                                                       baseY)
                                            withAttributes:markerAttributes];
                                     }

                                     didDrawMarker = YES;
                                     *stop =
                                         YES; // only first line of paragraph
                                   }];
    }
  }
}

- (NSString *)markerForList:(NSTextList *)list
                  charIndex:(NSUInteger)index
                      input:(EnrichedTextInputView *)input {

  if ([list.markerFormat isEqualToString:NSTextListMarkerDisc]) {
    return @"•";
  }

  NSTextStorage *ts = input->textView.textStorage;
  NSString *text = ts.string;

  NSRange currentParagraph =
      [text paragraphRangeForRange:NSMakeRange(index, 0)];

  if (currentParagraph.location == 0) {
    return @"1.";
  }

  NSParagraphStyle *currentStyle = [ts attribute:NSParagraphStyleAttributeName
                                         atIndex:currentParagraph.location
                                  effectiveRange:nil];

  NSInteger count = 1;
  NSUInteger location = currentParagraph.location;

  while (location > 0) {
    NSRange prevParagraph =
        [text paragraphRangeForRange:NSMakeRange(location - 1, 0)];

    NSParagraphStyle *prevStyle = [ts attribute:NSParagraphStyleAttributeName
                                        atIndex:prevParagraph.location
                                 effectiveRange:nil];

    BOOL isSameOrderedList = prevStyle.textLists.count > 0 &&
                             [prevStyle.textLists.firstObject.markerFormat
                                 isEqualToString:NSTextListMarkerDecimal] &&
                             prevStyle.alignment == currentStyle.alignment;

    if (!isSameOrderedList) {
      break;
    }

    count++;
    location = prevParagraph.location;
  }

  return [@(count).stringValue stringByAppendingString:@"."];
}

#pragma mark - Checklists

- (void)drawChecklists:(EnrichedTextInputView *)input
                origin:(CGPoint)origin
      visibleCharRange:(NSRange)visibleCharRange {

  CheckBoxStyle *style =
      (CheckBoxStyle *)input->stylesDict[@([CheckBoxStyle getStyleType])];
  if (!style)
    return;

  NSUInteger textLength = input->textView.textStorage.length;

  NSArray<StylePair *> *pairs = [style findAllOccurences:visibleCharRange];

  for (StylePair *pair in pairs) {
    NSArray *paragraphs = [ParagraphsUtils
        getSeparateParagraphsRangesIn:input->textView
                                range:pair.rangeValue.rangeValue];

    for (NSValue *p in paragraphs) {
      NSRange paragraph = NormalizeEmptyParagraph(p.rangeValue, textLength);

      NSRange glyphRange = [self glyphRangeForCharacterRange:paragraph
                                        actualCharacterRange:nil];

      BOOL checked = [style isCheckedAt:paragraph.location];

      UIImage *img =
          checked ? input->config.checkedImage : input->config.uncheckedImage;

      if (!img) {
        NSString *name = checked ? @"checkmark.square.fill" : @"square";
        img = [UIImage systemImageNamed:name];
      }

      CGFloat checkBoxWidth = input->config.checkBoxWidth;
      CGFloat checkBoxHeight = input->config.checkBoxHeight;
      CGFloat x = origin.x + input->config.checkboxListMarginLeft;

      [self enumerateLineFragmentsForGlyphRange:glyphRange
                                     usingBlock:^(CGRect rect, CGRect usedRect,
                                                  NSTextContainer *container,
                                                  NSRange lineGlyphRange,
                                                  BOOL *stop) {
                                       CGFloat y =
                                           origin.y + rect.origin.y +
                                           (rect.size.height - checkBoxHeight) /
                                               2.0;

                                       [img drawInRect:CGRectMake(
                                                           x, y, checkBoxWidth,
                                                           checkBoxHeight)];
                                       *stop = YES;
                                     }];
    }
  }
}

#pragma mark - Merge helpers

- (NSArray<StylePair *> *)mergeContiguousStylePairs:
    (NSArray<StylePair *> *)pairs {

  if (pairs.count == 0)
    return @[];

  NSMutableArray *result = [NSMutableArray new];
  NSRange current = pairs[0].rangeValue.rangeValue;
  StylePair *base = pairs[0];

  for (NSUInteger i = 1; i < pairs.count; i++) {
    NSRange next = pairs[i].rangeValue.rangeValue;
    if (NSMaxRange(current) == next.location) {
      current.length += next.length;
    } else {
      StylePair *p = [StylePair new];
      p.rangeValue = [NSValue valueWithRange:current];
      p.styleValue = base.styleValue;
      [result addObject:p];
      base = pairs[i];
      current = next;
    }
  }

  StylePair *last = [StylePair new];
  last.rangeValue = [NSValue valueWithRange:current];
  last.styleValue = base.styleValue;
  [result addObject:last];

  return result;
}

@end
