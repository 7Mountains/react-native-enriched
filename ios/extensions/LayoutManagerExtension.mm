#import "LayoutManagerExtension.h"
#import "ColorExtension.h"
#import "EnrichedStyleHost.h"
#import "EnrichedTextInputView.h"
#import "InputConfig.h"
#import "ParagraphsUtils.h"
#import "Strings.h"
#import "StyleHeaders.h"
#import "WeakBox.h"
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
  WeakBox *box = objc_getAssociatedObject(self, kInputKey);
  return box.value;
}

- (void)setInput:(id)value {
  WeakBox *box = objc_getAssociatedObject(self, kInputKey);
  if (!box) {
    box = [WeakBox new];
    objc_setAssociatedObject(self, kInputKey, box,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  box.value = value;
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

    SEL originalGlyphs = @selector(drawGlyphsForGlyphRange:atPoint:);
    SEL swizzledGlyphs = @selector(my_drawGlyphsForGlyphRange:atPoint:);

    Method originalGlyphsMethod =
        class_getInstanceMethod(myClass, originalGlyphs);
    Method swizzledGlyphsMethod =
        class_getInstanceMethod(myClass, swizzledGlyphs);

    method_exchangeImplementations(originalGlyphsMethod, swizzledGlyphsMethod);
    method_exchangeImplementations(originalMethod, swizzledMethod);
  });
}

#pragma mark - Entry point

- (void)my_drawGlyphsForGlyphRange:(NSRange)glyphsToShow
                           atPoint:(CGPoint)origin {
  id<EnrichedStyleHost> input = self.input;

  if (!input) {
    [self my_drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
    return;
  }

  [self drawCheckboxGlyps:input glyphsToShow:glyphsToShow origin:origin];
}

- (void)my_drawBackgroundForGlyphRange:(NSRange)glyphRange
                               atPoint:(CGPoint)origin {
  [self my_drawBackgroundForGlyphRange:glyphRange atPoint:origin];

  id<EnrichedStyleHost> input = self.input;
  if (!input)
    return;

  NSRange visibleCharRange = [self characterRangeForGlyphRange:glyphRange
                                              actualGlyphRange:nil];

  [self drawParagraphDecorations:input
                          origin:origin
                visibleCharRange:visibleCharRange];
}

#pragma mark - Paragraph decorations

// One pass for all of them: each is told by the paragraph style, a paragraph
// has at most one
- (void)drawParagraphDecorations:(id<EnrichedStyleHost>)input
                          origin:(CGPoint)origin
                visibleCharRange:(NSRange)visibleCharRange {
  NSDictionary *styles = input.stylesDict;
  BlockQuoteStyle *blockQuote = styles[@([BlockQuoteStyle getStyleType])];
  UnorderedListStyle *unorderedList =
      styles[@([UnorderedListStyle getStyleType])];
  OrderedListStyle *orderedList = styles[@([OrderedListStyle getStyleType])];
  CodeBlockStyle *codeBlock = styles[@([CodeBlockStyle getStyleType])];
  CheckBoxStyle *checkBox = styles[@([CheckBoxStyle getStyleType])];

  if (!blockQuote && !unorderedList && !orderedList && !codeBlock && !checkBox)
    return;

  [self.textStorage
      enumerateAttribute:NSParagraphStyleAttributeName
                 inRange:visibleCharRange
                 options:0
              usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (value == nil)
                  return;

                if ([blockQuote styleCondition:value range:range]) {
                  [self drawBlockQuote:input origin:origin range:range];
                } else if ([unorderedList styleCondition:value range:range] ||
                           [orderedList styleCondition:value range:range]) {
                  [self drawList:input origin:origin range:range];
                } else if ([codeBlock styleCondition:value range:range]) {
                  [self drawCodeBlock:input origin:origin range:range];
                } else if ([checkBox styleCondition:value range:range]) {
                  [self drawChecklist:input origin:origin range:range];
                }
              }];
}

#pragma mark - Code blocks

- (void)drawCodeBlock:(id<EnrichedStyleHost>)input
               origin:(CGPoint)origin
                range:(NSRange)range {
  UIColor *bg =
      [[input.config codeBlockBgColor] colorWithAlphaIfNotTransparent:0.4];
  CGFloat radius = [input.config codeBlockBorderRadius];
  [bg setFill];

  NSUInteger textLength = self.textStorage.length;

  NSRange blockRange = NormalizeEmptyParagraph(range, textLength);

  NSArray *paragraphs = [ParagraphsUtils
      getSeparateParagraphsRangesInAttributedString:self.textStorage
                                              range:blockRange];

  for (NSValue *p in paragraphs) {
    NSRange paragraph = NormalizeEmptyParagraph(p.rangeValue, textLength);

    NSRange glyphRange = [self glyphRangeForCharacterRange:paragraph
                                      actualCharacterRange:nil];

    __block BOOL isFirstLine = YES;

    [self enumerateLineFragmentsForGlyphRange:glyphRange
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

#pragma mark - Block quotes

- (void)drawBlockQuote:(id<EnrichedStyleHost>)input
                origin:(CGPoint)origin
                 range:(NSRange)range {

  BlockQuoteStyle *style =
      (BlockQuoteStyle *)input.stylesDict[@([BlockQuoteStyle getStyleType])];
  if (!style)
    return;

  NSString *text = self.textStorage.string;
  NSUInteger textLength = text.length;
  CGFloat gap = input.config.blockquoteGapWidth;
  UIFont *font = input.config.primaryFont;
  CGFloat naturalTextHeight = ceil(font.ascender - font.descender);

  NSDictionary *drawAttrs =
      @{NSForegroundColorAttributeName : input.config.blockquoteBorderColor};

  [text
      enumerateSubstringsInRange:range
                         options:NSStringEnumerationByParagraphs |
                                 NSStringEnumerationSubstringNotRequired
                      usingBlock:^(NSString *substring, NSRange paragraphRange,
                                   NSRange enclosingRange, BOOL *stop) {
                        NSRange safeRange =
                            NormalizeEmptyParagraph(paragraphRange, textLength);

                        NSDictionary *attrs = [self.textStorage
                            attributesAtIndex:safeRange.location
                               effectiveRange:nil];

                        NSParagraphStyle *paragraphStyle =
                            attrs[NSParagraphStyleAttributeName];

                        id value = attrs[[BlockQuoteStyle attributeKey]];
                        if (![style styleCondition:value
                                             range:NSMakeRange(
                                                       safeRange.location, 1)])
                          return;

                        NSRange glyphRange =
                            [self glyphRangeForCharacterRange:safeRange
                                         actualCharacterRange:nil];

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
                                                       CGFloat textLeft =
                                                           origin.x +
                                                           rect.origin.x +
                                                           usedRect.origin.x;

                                                       CGFloat textRight =
                                                           textLeft +
                                                           usedRect.size.width;

                                                       if (isFirstLine) {
                                                         NSString *openQuote =
                                                             @"“";

                                                         CGFloat quoteY =
                                                             origin.y +
                                                             CGRectGetMidY(
                                                                 rect) -
                                                             naturalTextHeight /
                                                                 2.0 +
                                                             paragraphStyle
                                                                 .paragraphSpacingBefore;

                                                         [openQuote
                                                                drawAtPoint:
                                                                    CGPointMake(
                                                                        textLeft -
                                                                            gap *
                                                                                2,
                                                                        quoteY)
                                                             withAttributes:
                                                                 drawAttrs];

                                                         isFirstLine = NO;
                                                       }

                                                       if (NSMaxRange(
                                                               lineGlyphRange) >=
                                                           NSMaxRange(
                                                               glyphRange)) {
                                                         NSString *closeQuote =
                                                             @"”";
                                                         CGFloat quoteY =
                                                             origin.y +
                                                             CGRectGetMidY(
                                                                 rect) -
                                                             naturalTextHeight /
                                                                 2.0 +
                                                             paragraphStyle
                                                                 .paragraphSpacingBefore;

                                                         [closeQuote
                                                                drawAtPoint:
                                                                    CGPointMake(
                                                                        textRight +
                                                                            gap,
                                                                        quoteY)
                                                             withAttributes:
                                                                 drawAttrs];
                                                       }
                                                     }];
                      }];
}

#pragma mark - Lists
- (void)drawList:(id<EnrichedStyleHost>)input
          origin:(CGPoint)origin
           range:(NSRange)range {
  NSTextStorage *textStorage = self.textStorage;
  NSUInteger textLength = textStorage.length;

  NSDictionary *markerAttributes = @{
    NSFontAttributeName : [input.config orderedListMarkerFont],
    NSForegroundColorAttributeName : [input.config orderedListMarkerColor]
  };

  CGFloat bulletSize = [input.config unorderedListBulletSize];

  NSArray<NSValue *> *paragraphs = [ParagraphsUtils
      getSeparateParagraphsRangesInAttributedString:self.textStorage
                                              range:range];

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

                                     CGFloat bulletX =
                                         baseX + indentWidth / 2.0;

                                     CGFloat bulletY =
                                         origin.y + CGRectGetMidY(rect);

                                     CGContextRef ctx =
                                         UIGraphicsGetCurrentContext();
                                     CGContextSaveGState(ctx);
                                     [[input.config unorderedListBulletColor]
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

                                     CGFloat markerWidth =
                                         [marker sizeWithAttributes:
                                                     markerAttributes]
                                             .width;

                                     CGFloat gap =
                                         [input.config orderedListGapWidth];

                                     CGFloat markerX = baseX + indentWidth -
                                                       markerWidth - gap;

                                     [marker drawAtPoint:CGPointMake(markerX,
                                                                     baseY)
                                          withAttributes:markerAttributes];
                                   }

                                   didDrawMarker = YES;
                                   *stop = YES; // only first line of paragraph
                                 }];
  }
}

- (NSString *)markerForList:(NSTextList *)list
                  charIndex:(NSUInteger)index
                      input:(id<EnrichedStyleHost>)input {

  if ([list.markerFormat isEqualToString:NSTextListMarkerDisc]) {
    return @"•";
  }

  NSTextStorage *ts = self.textStorage;
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

- (void)drawChecklist:(id<EnrichedStyleHost>)input
               origin:(CGPoint)origin
                range:(NSRange)range {

  CheckBoxStyle *style =
      (CheckBoxStyle *)input.stylesDict[@([CheckBoxStyle getStyleType])];
  if (!style)
    return;

  NSUInteger textLength = self.textStorage.length;

  NSArray *paragraphs = [ParagraphsUtils
      getSeparateParagraphsRangesInAttributedString:self.textStorage
                                              range:range];

  for (NSValue *p in paragraphs) {
    NSRange paragraph = NormalizeEmptyParagraph(p.rangeValue, textLength);

    NSRange glyphRange = [self glyphRangeForCharacterRange:paragraph
                                      actualCharacterRange:nil];

    BOOL checked = [CheckBoxStyle isCheckedAt:paragraph.location
                                       inText:self.textStorage];

    UIImage *img =
        checked ? input.config.checkedImage : input.config.uncheckedImage;

    if (!img) {
      NSString *name = checked ? @"checkmark.square.fill" : @"square";
      img = [UIImage systemImageNamed:name];
    }

    CGFloat checkBoxWidth = input.config.checkBoxWidth;
    CGFloat checkBoxHeight = input.config.checkBoxHeight;
    CGFloat x = origin.x + input.config.checkboxListMarginLeft;

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

static BOOL HasCheckedParagraph(NSTextStorage *textStorage, NSRange range) {
  __block BOOL hasChecked = NO;
  [textStorage enumerateAttribute:NSParagraphStyleAttributeName
                          inRange:range
                          options:0
                       usingBlock:^(NSParagraphStyle *paragraphStyle,
                                    NSRange __unused styleRange, BOOL *stop) {
                         if (paragraphStyle.textLists.count > 0 &&
                             [paragraphStyle.textLists.firstObject.markerFormat
                                 isEqualToString:NSTextListMarkerCheck]) {
                           hasChecked = YES;
                           *stop = YES;
                         }
                       }];
  return hasChecked;
}

- (void)drawCheckboxGlyps:(id<EnrichedStyleHost>)input
             glyphsToShow:(NSRange)glyphsToShow
                   origin:(CGPoint)origin {
  CGContextRef ctx = UIGraphicsGetCurrentContext();

  if (!ctx || !input) {
    [self my_drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
    return;
  }

  CheckBoxStyle *style =
      (CheckBoxStyle *)input.stylesDict[@([CheckBoxStyle getStyleType])];

  if (!style) {
    [self my_drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
    return;
  }

  // The text of this layout manager: the host shows it in a text view, or
  // draws it itself (EnrichedTextDrawingView)
  NSTextStorage *textStorage = self.textStorage;
  NSString *text = textStorage.string;
  UIColor *fallbackColor =
      input.textView.textColor ?: input.config.primaryColor;
  UIFont *font = input.config.primaryFont;
  CGFloat scale = UIScreen.mainScreen.scale;

  // Most texts have no checked checkbox: their glyphs are drawn at once, not
  // line by line
  NSRange charRange = [self characterRangeForGlyphRange:glyphsToShow
                                       actualGlyphRange:nil];
  if (!HasCheckedParagraph(textStorage,
                           [text paragraphRangeForRange:charRange])) {
    [self my_drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
    return;
  }

  static NSCharacterSet *newlineSet;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    newlineSet = [NSCharacterSet newlineCharacterSet];
  });

  [self
      enumerateLineFragmentsForGlyphRange:glyphsToShow
                               usingBlock:^(CGRect rect,
                                            CGRect __unused usedRect,
                                            NSTextContainer *container,
                                            NSRange lineGlyphRange,
                                            BOOL __unused *stop) {
                                 NSRange drawGlyphRange = NSIntersectionRange(
                                     lineGlyphRange, glyphsToShow);
                                 if (drawGlyphRange.length == 0) {
                                   return;
                                 }

                                 NSRange charRange = [self
                                     characterRangeForGlyphRange:lineGlyphRange
                                                actualGlyphRange:nil];

                                 NSRange paragraph =
                                     [text paragraphRangeForRange:charRange];
                                 BOOL checked = [CheckBoxStyle
                                     isCheckedAt:paragraph.location
                                          inText:self.textStorage];

                                 if (!checked) {
                                   [self
                                       my_drawGlyphsForGlyphRange:lineGlyphRange
                                                          atPoint:origin];
                                   return;
                                 }

                                 CGContextSaveGState(ctx);
                                 CGContextSetAlpha(ctx, 0.6);

                                 [self my_drawGlyphsForGlyphRange:lineGlyphRange
                                                          atPoint:origin];

                                 NSRange strikeCharRange = charRange;
                                 while (strikeCharRange.length > 0) {
                                   unichar lastChar = [text
                                       characterAtIndex:NSMaxRange(
                                                            strikeCharRange) -
                                                        1];

                                   if (![newlineSet
                                           characterIsMember:lastChar]) {
                                     break;
                                   }

                                   strikeCharRange.length -= 1;
                                 }

                                 if (strikeCharRange.length == 1 &&
                                     [text characterAtIndex:strikeCharRange
                                                                .location] ==
                                         ZWSChar) {
                                   CGContextRestoreGState(ctx);
                                   return;
                                 }

                                 if (strikeCharRange.length > 0) {
                                   CGContextSetLineCap(ctx, kCGLineCapButt);
                                   CGContextSetLineWidth(ctx, 1.0);
                                   [textStorage
                                       enumerateAttribute:
                                           NSForegroundColorAttributeName
                                                  inRange:strikeCharRange
                                                  options:0
                                               usingBlock:^(id attribute,
                                                            NSRange glyphRange,
                                                            BOOL *stop) {
                                                 UIColor *color =
                                                     ([attribute
                                                          isKindOfClass:
                                                              UIColor.class]
                                                          ? (UIColor *)attribute
                                                          : fallbackColor);

                                                 CGRect glyphRect = [self
                                                     boundingRectForGlyphRange:
                                                         glyphRange
                                                               inTextContainer:
                                                                   container];

                                                 CGPoint glyphLocation = [self
                                                     locationForGlyphAtIndex:
                                                         glyphRange.location];

                                                 CGFloat strikeY =
                                                     origin.y + rect.origin.y +
                                                     glyphLocation.y -
                                                     font.xHeight / 2.0;
                                                 strikeY =
                                                     round(strikeY * scale) /
                                                     scale;

                                                 CGContextSetStrokeColorWithColor(
                                                     ctx, color.CGColor);
                                                 CGContextMoveToPoint(
                                                     ctx,
                                                     origin.x +
                                                         glyphRect.origin.x,
                                                     strikeY);
                                                 CGContextAddLineToPoint(
                                                     ctx,
                                                     origin.x + CGRectGetMaxX(
                                                                    glyphRect),
                                                     strikeY);
                                                 CGContextStrokePath(ctx);
                                               }];
                                 }

                                 CGContextRestoreGState(ctx);
                               }];
}

@end
