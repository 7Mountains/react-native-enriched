"use strict";

import { useCallback, useEffect, useImperativeHandle, useMemo, useRef } from 'react';
import EnrichedTextInputNativeComponent, { Commands } from './EnrichedTextInputNativeComponent';
import { normalizeHtmlStyle } from "./normalizeHtmlStyle.js";
import { jsx as _jsx } from "react/jsx-runtime";
const nullthrows = value => {
  if (value == null) {
    throw new Error('Unexpected null or undefined value');
  }
  return value;
};
const warnAboutMissconfiguredMentions = indicator => {
  console.warn(`Looks like you are trying to set a "${indicator}" but it's not in the mentionIndicators prop`);
};
const DEFAULT_INSETS = {
  top: 0,
  left: 0,
  bottom: 0,
  right: 0
};
export const EnrichedTextInput = ({
  ref,
  autoFocus,
  editable = true,
  contentInsets = DEFAULT_INSETS,
  scrollIndicatorInsets = DEFAULT_INSETS,
  mentionIndicators = ['@'],
  defaultValue,
  placeholder,
  placeholderTextColor,
  cursorColor,
  selectionColor,
  style,
  autoCapitalize = 'sentences',
  htmlStyle = {},
  onFocus,
  onBlur,
  onChangeText,
  onChangeHtml,
  onChangeState,
  onLinkDetected,
  onMentionDetected,
  onStartMention,
  onChangeMention,
  onEndMention,
  onChangeSelection,
  onColorChangeInSelection,
  onParagraphAlignmentChange,
  onScroll,
  androidExperimentalSynchronousEvents = false,
  scrollEnabled = true,
  keyboardDismissMode = 'none',
  ...rest
}) => {
  const nativeRef = useRef(null);
  const nextHtmlRequestId = useRef(1);
  const pendingHtmlRequests = useRef(new Map());
  useEffect(() => {
    const pendingRequests = pendingHtmlRequests.current;
    return () => {
      pendingRequests.forEach(({
        reject
      }) => {
        reject(new Error('Component unmounted'));
      });
      pendingRequests.clear();
    };
  }, []);
  const normalizedHtmlStyle = useMemo(() => normalizeHtmlStyle(htmlStyle, mentionIndicators), [htmlStyle, mentionIndicators]);
  useImperativeHandle(ref, () => ({
    measureInWindow: callback => {
      nullthrows(nativeRef.current).measureInWindow(callback);
    },
    measure: callback => {
      nullthrows(nativeRef.current).measure(callback);
    },
    measureLayout: (relativeToNativeComponentRef, onSuccess, onFail) => {
      nullthrows(nativeRef.current).measureLayout(relativeToNativeComponentRef, onSuccess, onFail);
    },
    setNativeProps: nativeProps => {
      nullthrows(nativeRef.current).setNativeProps(nativeProps);
    },
    focus: () => {
      Commands.focus(nullthrows(nativeRef.current));
    },
    blur: () => {
      Commands.blur(nullthrows(nativeRef.current));
    },
    setValue: value => {
      Commands.setValue(nullthrows(nativeRef.current), value);
    },
    getHTML: (prettify = false) => new Promise((resolve, reject) => {
      const requestId = nextHtmlRequestId.current++;
      pendingHtmlRequests.current.set(requestId, {
        resolve,
        reject
      });
      Commands.requestHTML(nullthrows(nativeRef.current), requestId, prettify);
    }),
    toggleBold: () => {
      Commands.toggleBold(nullthrows(nativeRef.current));
    },
    toggleItalic: () => {
      Commands.toggleItalic(nullthrows(nativeRef.current));
    },
    toggleUnderline: () => {
      Commands.toggleUnderline(nullthrows(nativeRef.current));
    },
    toggleStrikeThrough: () => {
      Commands.toggleStrikeThrough(nullthrows(nativeRef.current));
    },
    toggleInlineCode: () => {
      Commands.toggleInlineCode(nullthrows(nativeRef.current));
    },
    toggleH1: () => {
      Commands.toggleH1(nullthrows(nativeRef.current));
    },
    toggleH2: () => {
      Commands.toggleH2(nullthrows(nativeRef.current));
    },
    toggleH3: () => {
      Commands.toggleH3(nullthrows(nativeRef.current));
    },
    toggleH4: () => {
      Commands.toggleH4(nullthrows(nativeRef.current));
    },
    toggleH5: () => {
      Commands.toggleH5(nullthrows(nativeRef.current));
    },
    toggleH6: () => {
      Commands.toggleH6(nullthrows(nativeRef.current));
    },
    toggleCodeBlock: () => {
      Commands.toggleCodeBlock(nullthrows(nativeRef.current));
    },
    toggleBlockQuote: () => {
      Commands.toggleBlockQuote(nullthrows(nativeRef.current));
    },
    toggleOrderedList: () => {
      Commands.toggleOrderedList(nullthrows(nativeRef.current));
    },
    toggleUnorderedList: () => {
      Commands.toggleUnorderedList(nullthrows(nativeRef.current));
    },
    setLink: (start, end, text, url) => {
      Commands.addLink(nullthrows(nativeRef.current), start, end, text, url);
    },
    setImage: (uri, width, height) => {
      Commands.addImage(nullthrows(nativeRef.current), uri, width, height);
    },
    setMention: (indicator, text, attributes) => {
      // Codegen does not support objects as Commands parameters, so we stringify attributes
      const parsedAttributes = JSON.stringify(attributes ?? {});
      Commands.addMention(nullthrows(nativeRef.current), indicator, text, parsedAttributes);
    },
    startMention: indicator => {
      if (!mentionIndicators?.includes(indicator)) {
        warnAboutMissconfiguredMentions(indicator);
      }
      Commands.startMention(nullthrows(nativeRef.current), indicator);
    },
    setSelection: (start, end) => {
      Commands.setSelection(nullthrows(nativeRef.current), start, end);
    },
    toggleCheckList: () => {
      Commands.toggleCheckList(nullthrows(nativeRef.current));
    },
    setColor: color => {
      Commands.setColor(nullthrows(nativeRef.current), color);
    },
    removeColor: () => {
      Commands.removeColor(nullthrows(nativeRef.current));
    },
    addDividerAtNewLine: () => Commands.addDividerAtNewLine(nullthrows(nativeRef.current)),
    setParagraphAlignment: alignment => {
      Commands.setParagraphAlignment(nullthrows(nativeRef.current), alignment);
    },
    scrollTo: (x, y, animated = true) => {
      Commands.scrollTo(nullthrows(nativeRef.current), x, y, animated);
    }
  }));
  const handleMentionEvent = useCallback(e => {
    const mentionText = e.nativeEvent.text;
    const mentionIndicator = e.nativeEvent.indicator;
    if (typeof mentionText === 'string') {
      if (mentionText === '') {
        onStartMention?.(mentionIndicator);
      } else {
        onChangeMention?.({
          indicator: mentionIndicator,
          text: mentionText
        });
      }
    } else if (mentionText === null) {
      onEndMention?.(mentionIndicator);
    }
  }, [onStartMention, onChangeMention, onEndMention]);
  const handleLinkDetected = useCallback(e => {
    const {
      text,
      url,
      start,
      end
    } = e.nativeEvent;
    onLinkDetected?.({
      text,
      url,
      start,
      end
    });
  }, [onLinkDetected]);
  const handleMentionDetected = useCallback(e => {
    const {
      text,
      indicator,
      payload
    } = e.nativeEvent;
    const attributes = JSON.parse(payload);
    onMentionDetected?.({
      text,
      indicator,
      attributes
    });
  }, [onMentionDetected]);
  const handleRequestHtmlResult = useCallback(e => {
    const {
      requestId,
      html
    } = e.nativeEvent;
    const pending = pendingHtmlRequests.current.get(requestId);
    if (!pending) return;
    if (html === null || typeof html !== 'string') {
      pending.reject(new Error('Failed to parse HTML'));
    } else {
      pending.resolve(html);
    }
    pendingHtmlRequests.current.delete(requestId);
  }, []);
  return /*#__PURE__*/_jsx(EnrichedTextInputNativeComponent, {
    ref: nativeRef,
    mentionIndicators: mentionIndicators,
    editable: editable,
    contentInsets: contentInsets,
    scrollIndicatorInsets: scrollIndicatorInsets,
    autoFocus: autoFocus,
    defaultValue: defaultValue,
    placeholder: placeholder,
    placeholderTextColor: placeholderTextColor,
    cursorColor: cursorColor,
    selectionColor: selectionColor,
    style: style,
    autoCapitalize: autoCapitalize,
    htmlStyle: normalizedHtmlStyle,
    onInputFocus: onFocus,
    onInputBlur: onBlur,
    onChangeText: onChangeText,
    onChangeHtml: onChangeHtml,
    isOnChangeHtmlSet: onChangeHtml !== undefined,
    onChangeState: onChangeState,
    onLinkDetected: handleLinkDetected,
    onMentionDetected: handleMentionDetected,
    onMention: handleMentionEvent,
    onChangeSelection: onChangeSelection,
    onRequestHtmlResult: handleRequestHtmlResult,
    onColorChangeInSelection: onColorChangeInSelection,
    onParagraphAlignmentChange: onParagraphAlignmentChange,
    isOnChangeTextSet: onChangeText !== undefined,
    isOnScrollSet: onScroll !== undefined,
    onInputScroll: onScroll,
    androidExperimentalSynchronousEvents: androidExperimentalSynchronousEvents,
    keyboardDismissMode: keyboardDismissMode,
    scrollEnabled: scrollEnabled,
    ...rest
  });
};
//# sourceMappingURL=EnrichedTextInput.js.map