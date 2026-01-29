import { useEffect, useMemo, useRef } from 'react';
import EnrichedTextInputNativeComponent from './EnrichedTextInputNativeComponent';
import { normalizeHtmlStyle } from './normalizeHtmlStyle';
import type { EnrichedTextInputProps, HtmlRequest } from './types';
import { useCommands } from './hooks/useCommands';
import { useHandlers } from './hooks/useHandlers';

const DEFAULT_INSETS = {
  top: 0,
  left: 0,
  bottom: 0,
  right: 0,
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
}: EnrichedTextInputProps) => {
  const nextHtmlRequestId = useRef(1);
  const pendingHtmlRequests = useRef(new Map<number, HtmlRequest>());

  useEffect(() => {
    const pendingRequests = pendingHtmlRequests.current;
    return () => {
      pendingRequests.forEach(({ reject }) => {
        reject(new Error('Component unmounted'));
      });
      pendingRequests.clear();
    };
  }, []);

  const normalizedHtmlStyle = useMemo(
    () => normalizeHtmlStyle(htmlStyle, mentionIndicators),
    [htmlStyle, mentionIndicators]
  );

  useCommands(ref, mentionIndicators, nextHtmlRequestId, pendingHtmlRequests);

  const {
    handleMentionEvent,
    handleLinkDetected,
    handleMentionDetected,
    handleRequestHtmlResult,
  } = useHandlers({
    onStartMention,
    onChangeMention,
    onEndMention,
    onLinkDetected,
    onMentionDetected,
    pendingHtmlRequests,
  });

  return (
    <EnrichedTextInputNativeComponent
      // @ts-ignore
      ref={ref}
      mentionIndicators={mentionIndicators}
      editable={editable}
      contentInsets={contentInsets}
      scrollIndicatorInsets={scrollIndicatorInsets}
      autoFocus={autoFocus}
      defaultValue={defaultValue}
      placeholder={placeholder}
      placeholderTextColor={placeholderTextColor}
      cursorColor={cursorColor}
      selectionColor={selectionColor}
      style={style}
      autoCapitalize={autoCapitalize}
      htmlStyle={normalizedHtmlStyle}
      onInputFocus={onFocus}
      onInputBlur={onBlur}
      onChangeText={onChangeText}
      onChangeHtml={onChangeHtml}
      isOnChangeHtmlSet={onChangeHtml !== undefined}
      onChangeState={onChangeState}
      onLinkDetected={handleLinkDetected}
      onMentionDetected={handleMentionDetected}
      onMention={handleMentionEvent}
      onChangeSelection={onChangeSelection}
      onRequestHtmlResult={handleRequestHtmlResult}
      onColorChangeInSelection={onColorChangeInSelection}
      onParagraphAlignmentChange={onParagraphAlignmentChange}
      isOnChangeTextSet={onChangeText !== undefined}
      isOnScrollSet={onScroll !== undefined}
      onInputScroll={onScroll}
      androidExperimentalSynchronousEvents={
        androidExperimentalSynchronousEvents
      }
      keyboardDismissMode={keyboardDismissMode}
      scrollEnabled={scrollEnabled}
      {...rest}
    />
  );
};
