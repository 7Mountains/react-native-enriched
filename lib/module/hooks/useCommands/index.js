"use strict";

import { useImperativeHandle } from 'react';
import { Commands } from '../../EnrichedTextInputNativeComponent';
const nullthrows = value => {
  if (value == null) {
    throw new Error('Unexpected null or undefined value');
  }
  return value;
};
const warnAboutMissconfiguredMentions = indicator => {
  console.warn(`Looks like you are trying to set a "${indicator}" but it's not in the mentionIndicators prop`);
};
const useCommands = (ref, nativeRef, mentionIndicators, nextHtmlRequestId, pendingHtmlRequests) => useImperativeHandle(ref, () => {
  const typedRef = nativeRef?.current;
  return {
    ...typedRef,
    measureInWindow: callback => {
      nullthrows(ref?.current).measureInWindow(callback);
    },
    measure: callback => {
      nullthrows(ref?.current).measure(callback);
    },
    measureLayout: (relativeToNativeComponentRef, onSuccess, onFail) => {
      nullthrows(ref?.current).measureLayout(relativeToNativeComponentRef, onSuccess, onFail);
    },
    setNativeProps: nativeProps => {
      nullthrows(ref?.current).setNativeProps(nativeProps);
    },
    focus: () => {
      Commands.focus(nullthrows(typedRef));
    },
    blur: () => {
      Commands.blur(nullthrows(typedRef));
    },
    setValue: value => {
      Commands.setValue(nullthrows(typedRef), value);
    },
    getHTML: (prettify = false) => new Promise((resolve, reject) => {
      const requestId = nextHtmlRequestId.current++;
      pendingHtmlRequests.current.set(requestId, {
        resolve,
        reject
      });
      Commands.requestHTML(nullthrows(typedRef), requestId, prettify);
    }),
    toggleBold: () => {
      Commands.toggleBold(nullthrows(typedRef));
    },
    toggleItalic: () => {
      Commands.toggleItalic(nullthrows(typedRef));
    },
    toggleUnderline: () => {
      Commands.toggleUnderline(nullthrows(typedRef));
    },
    toggleStrikeThrough: () => {
      Commands.toggleStrikeThrough(nullthrows(typedRef));
    },
    toggleInlineCode: () => {
      Commands.toggleInlineCode(nullthrows(typedRef));
    },
    toggleH1: () => {
      Commands.toggleH1(nullthrows(typedRef));
    },
    toggleH2: () => {
      Commands.toggleH2(nullthrows(typedRef));
    },
    toggleH3: () => {
      Commands.toggleH3(nullthrows(typedRef));
    },
    toggleH4: () => {
      Commands.toggleH4(nullthrows(typedRef));
    },
    toggleH5: () => {
      Commands.toggleH5(nullthrows(typedRef));
    },
    toggleH6: () => {
      Commands.toggleH6(nullthrows(typedRef));
    },
    toggleCodeBlock: () => {
      Commands.toggleCodeBlock(nullthrows(typedRef));
    },
    toggleBlockQuote: () => {
      Commands.toggleBlockQuote(nullthrows(typedRef));
    },
    toggleOrderedList: () => {
      Commands.toggleOrderedList(nullthrows(typedRef));
    },
    toggleUnorderedList: () => {
      Commands.toggleUnorderedList(nullthrows(typedRef));
    },
    setLink: (start, end, text, url) => {
      Commands.addLink(nullthrows(typedRef), start, end, text, url);
    },
    setImage: (uri, width, height) => {
      Commands.addImage(nullthrows(typedRef), uri, width, height);
    },
    setMention: (indicator, text, attributes) => {
      // Codegen does not support objects as Commands parameters, so we stringify attributes
      const parsedAttributes = JSON.stringify(attributes ?? {});
      Commands.addMention(nullthrows(typedRef), indicator, text, parsedAttributes);
    },
    startMention: indicator => {
      if (!mentionIndicators?.includes(indicator)) {
        warnAboutMissconfiguredMentions(indicator);
      }
      Commands.startMention(nullthrows(typedRef), indicator);
    },
    setSelection: (start, end) => {
      Commands.setSelection(nullthrows(typedRef), start, end);
    },
    toggleCheckList: () => {
      Commands.toggleCheckList(nullthrows(typedRef));
    },
    setColor: color => {
      Commands.setColor(nullthrows(typedRef), color);
    },
    removeColor: () => {
      Commands.removeColor(nullthrows(typedRef));
    },
    addDividerAtNewLine: () => Commands.addDividerAtNewLine(nullthrows(typedRef)),
    setParagraphAlignment: alignment => {
      Commands.setParagraphAlignment(nullthrows(typedRef), alignment);
    },
    scrollTo: (x, y, animated = false) => {
      Commands.scrollTo(nullthrows(typedRef), x, y, animated);
    },
    addContent: (text, type, src, headers, attributes) => {
      Commands.addContent(nullthrows(typedRef), text, type, src, headers, attributes);
    }
  };
}, [mentionIndicators, nextHtmlRequestId, pendingHtmlRequests, nativeRef, ref]);
export { useCommands };
//# sourceMappingURL=index.js.map