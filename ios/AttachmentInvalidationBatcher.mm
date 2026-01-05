#import "AttachmentInvalidationBatcher.h"

@implementation AttachmentInvalidationBatcher {
  BOOL _isProcessing;
  NSMutableSet *_pending;
  NSMutableSet *_nextBatch;
  UITextView __weak *_textView;
}

- (instancetype)initWithTextView:(UITextView *)textView {
  self = [super init];
  if (!self)
    return nil;

  _textView = textView;
  _pending = [NSMutableSet set];
  _nextBatch = [NSMutableSet set];
  _isProcessing = NO;

  return self;
}

#pragma mark - Public API

- (void)enqueueAttachment:(NSTextAttachment *)attachment {
  if (!attachment)
    return;

  [_pending addObject:attachment];

  if (!_isProcessing) {
    [self scheduleTick];
  }
}

#pragma mark - Tick

- (void)scheduleTick {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self processPending];
  });
}

- (void)processPending {
  if (_isProcessing)
    return;

  _isProcessing = YES;

  NSTextStorage *storage = _textView.textStorage;
  NSLayoutManager *layoutManager = _textView.layoutManager;
  if (_pending.count == 0) {
    _isProcessing = NO;
    return;
  }

  NSMutableSet<NSTextAttachment *> *targets = [_pending mutableCopy];
  [_pending removeAllObjects];

  NSRange fullRange = NSMakeRange(0, storage.length);

  [storage enumerateAttribute:NSAttachmentAttributeName
                      inRange:fullRange
                      options:0
                   usingBlock:^(id value, NSRange range, BOOL *stop) {
                     if (!value)
                       return;

                     if ([targets containsObject:value]) {
                       [layoutManager
                           invalidateLayoutForCharacterRange:range
                                        actualCharacterRange:nullptr];
                       [layoutManager invalidateDisplayForCharacterRange:range];
                       [targets removeObject:value];
                     }
                   }];

  _isProcessing = NO;
  // if we added a new quee while processing we have to schedule a new tick
  // right after processing
  if (_pending.count > 0) {
    [self scheduleTick];
  }
}

@end
