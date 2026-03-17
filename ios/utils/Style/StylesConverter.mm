#import "StylesConverter.h"

@implementation StylesConverter

+ (StyleType)styleTypeFromString:(NSString *)style {

  static NSDictionary<NSString *, NSNumber *> *map;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    map = @{
      @"blockquote" : @(BlockQuote),
      @"codeblock" : @(CodeBlock),
      @"ul" : @(UnorderedList),
      @"ol" : @(OrderedList),

      @"h1" : @(H1),
      @"h2" : @(H2),
      @"h3" : @(H3),
      @"h4" : @(H4),
      @"h5" : @(H5),
      @"h6" : @(H6),

      @"checkbox" : @(Checkbox),
      @"divider" : @(Divider),
      @"content" : @(Content),
      @"mdf" : @(MDF),
      @"align" : @(ParagraphAlignment),
      @"link" : @(Link),
      @"mention" : @(Mention),
      @"image" : @(Image),

      @"inlinecode" : @(InlineCode),

      @"bold" : @(Bold),
      @"italic" : @(Italic),
      @"underline" : @(Underline),
      @"strike" : @(Strikethrough),
      @"color" : @(Colored),
    };
  });

  NSNumber *value = map[style.lowercaseString];
  return value ? (StyleType)value.integerValue : None;
}

+ (NSString *)styleNameFromType:(StyleType)type {

  static NSDictionary<NSNumber *, NSString *> *map;
  static dispatch_once_t onceToken;

  dispatch_once(&onceToken, ^{
    map = @{
      @(BlockQuote) : @"blockquote",
      @(CodeBlock) : @"codeblock",

      @(UnorderedList) : @"ul",
      @(OrderedList) : @"ol",

      @(H1) : @"h1",
      @(H2) : @"h2",
      @(H3) : @"h3",
      @(H4) : @"h4",
      @(H5) : @"h5",
      @(H6) : @"h6",

      @(Checkbox) : @"checkbox",
      @(Divider) : @"divider",
      @(Content) : @"content",
      @(MDF) : @"mdf",

      @(ParagraphAlignment) : @"align",

      @(Link) : @"link",
      @(Mention) : @"mention",
      @(Image) : @"image",

      @(InlineCode) : @"inlineCode",

      @(Bold) : @"bold",
      @(Italic) : @"italic",
      @(Underline) : @"underline",
      @(Strikethrough) : @"strike",
      @(Colored) : @"color",
    };
  });

  NSString *name = map[@(type)];
  return name ?: @"";
}

@end
