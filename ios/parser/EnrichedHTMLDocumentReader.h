#pragma once
#import <Foundation/Foundation.h>
#import <libxml/HTMLparser.h>

NS_ASSUME_NONNULL_BEGIN

// The document of an html in UTF-8, read with the html parser of the current
// thread: reset by each read instead of created and freed for every document.
// Freed by the caller (`xmlFreeDoc`), `NULL` when it can't be read
htmlDocPtr _Nullable EnrichedReadHTMLDocument(const char *html, size_t length);

NS_ASSUME_NONNULL_END
