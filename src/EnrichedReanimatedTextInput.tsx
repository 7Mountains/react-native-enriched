import { type ComponentProps, useEffect, useMemo, useRef } from 'react';
import EnrichedTextInputNativeComponent from './EnrichedTextInputNativeComponent';
import { normalizeHtmlStyle } from './normalizeHtmlStyle';
import type {
  EnrichedTextInputInstance,
  EnrichedTextInputProps,
  HtmlRequest,
} from './types';
import { useCommands } from './hooks/useCommands';
import { useHandlers } from './hooks/useHandlers';
import Reanimated, { type AnimatedRef } from 'react-native-reanimated';

const DEFAULT_INSETS = {
  top: 0,
  left: 0,
  bottom: 0,
  right: 0,
};

const EnrichedReanimatedNativeComponent = Reanimated.createAnimatedComponent(
  EnrichedTextInputNativeComponent
);

export const EnrichedReanimatedTextInput = ({
  ref,
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
  ...rest
}: EnrichedTextInputProps &
  Exclude<
    ComponentProps<typeof EnrichedReanimatedNativeComponent>,
    'htmlStyle'
  > & {
    ref?: AnimatedRef<EnrichedTextInputInstance>;
  }) => {
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
    <EnrichedReanimatedNativeComponent
      ref={ref}
      {...rest}
      mentionIndicators={mentionIndicators}
      editable={editable}
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
      androidExperimentalSynchronousEvents={
        androidExperimentalSynchronousEvents
      }
      contentInsets={contentInsets}
      keyboardDismissMode={keyboardDismissMode}
      scrollEnabled={scrollEnabled}
    />
  );
};
