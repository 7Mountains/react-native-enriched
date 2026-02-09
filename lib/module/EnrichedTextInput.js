"use strict";

import { useEffect, useMemo, useRef } from 'react';
import EnrichedTextInputNativeComponent from './EnrichedTextInputNativeComponent';
import { normalizeHtmlStyle } from "./normalizeHtmlStyle.js";
import { useCommands } from "./hooks/useCommands/index.js";
import { useHandlers } from "./hooks/useHandlers/index.js";
import { jsx as _jsx } from "react/jsx-runtime";
const DEFAULT_INSETS = {
  top: 0,
  left: 0,
  bottom: 0,
  right: 0
};
export const EnrichedTextInput = ({
  ref,
  autoFocus,
  automaticallyAdjustsScrollIndicatorInsets = true,
  automaticallyAdjustContentInsets = true,
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
  const normalizedHtmlStyle = useMemo(() => normalizeHtmlStyle(htmlStyle), [htmlStyle]);
  useCommands(ref, nativeRef, mentionIndicators, nextHtmlRequestId, pendingHtmlRequests);
  const {
    handleMentionEvent,
    handleLinkDetected,
    handleMentionDetected,
    handleRequestHtmlResult
  } = useHandlers({
    onStartMention,
    onChangeMention,
    onEndMention,
    onLinkDetected,
    onMentionDetected,
    pendingHtmlRequests
  });
  return /*#__PURE__*/_jsx(EnrichedTextInputNativeComponent, {
    ref: nativeRef,
    mentionIndicators: mentionIndicators,
    editable: editable,
    contentInsets: contentInsets,
    scrollIndicatorInsets: scrollIndicatorInsets,
    automaticallyAdjustsScrollIndicatorInsets: automaticallyAdjustsScrollIndicatorInsets,
    automaticallyAdjustContentInsets: automaticallyAdjustContentInsets,
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