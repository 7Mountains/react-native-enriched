#pragma once
#import "MediaAttachment.h"

@interface BaseImageAttachment : MediaAttachment

@property(nonatomic, assign) BOOL needsRedraw;
@property(nonatomic, readonly) NSString *fallbackUri;

- (void)invalidateCache;
- (void)loadImageAsyncWithURI:(NSString *)uri;

#pragma mark - Override in subclasses
- (void)drawContentInBounds:(CGRect)bounds context:(CGContextRef)ctx;

@end
