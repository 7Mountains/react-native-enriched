#import "EnrichedHTMLDocumentReader.h"

// Compact: the short texts are kept in their nodes, not allocated apart
static const int kReadOptions = HTML_PARSE_NOERROR | HTML_PARSE_NOWARNING |
                                HTML_PARSE_RECOVER | HTML_PARSE_COMPACT;

// Its dictionary keeps the names it reads (e.g. the tags and the
// attributes): created again when it grows past them
static htmlParserCtxtPtr ThreadParserContext(void) {
  struct Holder {
    htmlParserCtxtPtr context = nullptr;

    ~Holder() {
      if (context != nullptr) {
        htmlFreeParserCtxt(context);
      }
    }
  };
  static thread_local Holder holder;
  static const size_t kMaxDictionarySize = 4096;

  if (holder.context != nullptr && holder.context->dict != nullptr &&
      xmlDictSize(holder.context->dict) > kMaxDictionarySize) {
    htmlFreeParserCtxt(holder.context);
    holder.context = nullptr;
  }
  if (holder.context == nullptr) {
    holder.context = htmlNewParserCtxt();
  }
  return holder.context;
}

htmlDocPtr EnrichedReadHTMLDocument(const char *html, size_t length) {
  htmlParserCtxtPtr context = ThreadParserContext();
  return context != nullptr
             ? htmlCtxtReadMemory(context, html, (int)length, NULL, "UTF-8",
                                  kReadOptions)
             : htmlReadMemory(html, (int)length, NULL, "UTF-8", kReadOptions);
}
