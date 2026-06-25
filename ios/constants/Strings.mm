#import "Strings.h"

NSString *const ZWS = @"\u200B";
NSString *const NewLine = @"\n";
NSString *const LineSeparator = @"\u2028";
NSString *const Tab = @"\t";
NSString *const ZWSWithNewLine = @"\u200B\n";
NSString *const ORC = @"\uFFFC";
NSString *const NewLineWithZWS = @"\n\u200B";

unichar const ZWSChar = 0x200B;
const char *NewLineChar = "\n";
unichar const ORCChar = 0xFFFC;
unichar const NewLineUniChar = 0x000A;

unichar const NewLineUnsinedChar = '\n';
