#import "AttachmentInvalidationBatcher.h"

@interface AttachmentInvalidationBatcher ()

@property(nonatomic, weak) UITextView *textView;
@property(nonatomic, strong) NSMutableSet<NSTextAttachment *> *pending;
@property(nonatomic, strong) NSMutableSet<NSTextAttachment *> *nextBatch;
@property(nonatomic) BOOL isProcessing;

@end

@implementation AttachmentInvalidationBatcher

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

  [self.pending addObject:attachment];

  if (!self.isProcessing) {
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
  if (self.isProcessing)
    return;

  self.isProcessing = YES;

  NSTextStorage *storage = self.textView.textStorage;
  if (!storage || self.pending.count == 0) {
    self.isProcessing = NO;
    return;
  }

  NSSet<NSTextAttachment *> *targets = [self.pending copy];
  [self.pending removeAllObjects];

  NSRange fullRange = NSMakeRange(0, storage.length);

  [storage beginEditing];

  [storage enumerateAttribute:NSAttachmentAttributeName
                      inRange:fullRange
                      options:0
                   usingBlock:^(id value, NSRange range, BOOL *stop) {
                     if (!value)
                       return;

                     if ([targets containsObject:value]) {
                       [storage edited:NSTextStorageEditedAttributes
                                    range:range
                           changeInLength:0];
                     }
                   }];

  [storage endEditing];

  self.isProcessing = NO;

  if (self.pending.count > 0) {
    [self scheduleTick];
  }
}

#pragma mark - Invalidation

- (void)invalidateAttachment:(NSTextAttachment *)attachment
                   inStorage:(NSTextStorage *)storage {

  NSRange fullRange = NSMakeRange(0, storage.length);

  [storage enumerateAttribute:NSAttachmentAttributeName
                      inRange:fullRange
                      options:0
                   usingBlock:^(id value, NSRange range, BOOL *stop) {
                     if (value == attachment) {
                       [storage edited:NSTextStorageEditedAttributes
                                    range:range
                           changeInLength:0];
                       *stop = YES;
                     }
                   }];
}

@end
