"use strict";

import { useEffect, useMemo, useRef } from 'react';
import EnrichedTextInputNativeComponent from './EnrichedTextInputNativeComponent';
import { normalizeHtmlStyle } from "./normalizeHtmlStyle.js";
import { useCommands } from "./hooks/useCommands/index.js";
import { useHandlers } from "./hooks/useHandlers/index.js";
import Reanimated, { useAnimatedRef } from 'react-native-reanimated';
import { jsx as _jsx } from "react/jsx-runtime";
const DEFAULT_INSETS = {
  top: 0,
  left: 0,
  bottom: 0,
  right: 0
};
const EnrichedReanimatedNativeComponent = Reanimated.createAnimatedComponent(EnrichedTextInputNativeComponent);
export const EnrichedReanimatedTextInput = ({
  ref,
  automaticallyAdjustsScrollIndicatorInsets = true,
  automaticallyAdjustContentInsets = true,
  autoFocus,
  editable = true,
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
  contentInsets = DEFAULT_INSETS,
  androidExperimentalSynchronousEvents = false,
  scrollEnabled = true,
  keyboardDismissMode = 'none',
  onScroll,
  ...rest
}) => {
  const nativeRef = useAnimatedRef();
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
  return /*#__PURE__*/_jsx(EnrichedReanimatedNativeComponent, {
    ref: nativeRef,
    ...rest,
    automaticallyAdjustsScrollIndicatorInsets: automaticallyAdjustsScrollIndicatorInsets,
    automaticallyAdjustContentInsets: automaticallyAdjustContentInsets,
    mentionIndicators: mentionIndicators,
    editable: editable,
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
    androidExperimentalSynchronousEvents: androidExperimentalSynchronousEvents,
    onInputScroll: onScroll,
    isOnScrollSet: onScroll !== undefined,
    contentInsets: contentInsets,
    keyboardDismissMode: keyboardDismissMode,
    scrollEnabled: scrollEnabled
  });
};
//# sourceMappingURL=EnrichedReanimatedTextInput.js.map