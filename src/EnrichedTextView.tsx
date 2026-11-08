import { useMemo } from 'react';
import {
  Platform,
  Text,
  type NativeSyntheticEvent,
  type TextProps,
} from 'react-native';

import EnrichedTextViewNativeComponent, {
  type OnLinkPressEvent,
  type OnMentionPressEvent,
  type OnMentionPressEventInternal,
} from './EnrichedTextNativeComponent';
import { normalizeHtmlStyle } from './normalizeHtmlStyle';
import type { EnrichedTextViewProps, HtmlStyle } from './types';

const EMPTY_HTML_STYLE: HtmlStyle = {};

const HTML_ENTITIES: Record<string, string> = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&nbsp;': ' ',
};

const stripHtml = (html: string) =>
  html
    .replace(/<\/(p|h[1-6]|li|blockquote|codeblock)>|<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&(amp|lt|gt|quot|#39|nbsp);/g, (entity) => HTML_ENTITIES[entity]!)
    .trim();

const useLinkHandler = (handler?: (event: OnLinkPressEvent) => void) =>
  useMemo(
    () =>
      handler
        ? ({ nativeEvent }: NativeSyntheticEvent<OnLinkPressEvent>) =>
            handler(nativeEvent)
        : undefined,
    [handler]
  );

const useMentionHandler = (handler?: (event: OnMentionPressEvent) => void) =>
  useMemo(
    () =>
      handler
        ? ({
            nativeEvent: { text, indicator, type, attributes },
          }: NativeSyntheticEvent<OnMentionPressEventInternal>) =>
            handler({
              text,
              indicator,
              type,
              attributes: attributes as Record<string, string>,
            })
        : undefined,
    [handler]
  );

/**
 * Shows enriched text in the selectable display renderer. Unlike
 * `EnrichedText`, this component uses a native selectable text view.
 */
export const EnrichedTextView = ({
  children,
  style,
  htmlStyle = EMPTY_HTML_STYLE,
  numberOfLines = 0,
  ellipsizeMode = 'tail',
  selectable = true,
  selectionColor,
  allowFontScaling = true,
  onLinkPressIn,
  onLinkPressOut,
  onLinkPress,
  onLinkLongPress,
  onMentionPressIn,
  onMentionPressOut,
  onMentionPress,
  onMentionLongPress,
  ...rest
}: EnrichedTextViewProps) => {
  const normalizedHtmlStyle = useMemo(
    () => normalizeHtmlStyle(htmlStyle),
    [htmlStyle]
  );

  const handleLinkPressIn = useLinkHandler(onLinkPressIn);
  const handleLinkPressOut = useLinkHandler(onLinkPressOut);
  const handleLinkPress = useLinkHandler(onLinkPress);
  const handleLinkLongPress = useLinkHandler(onLinkLongPress);
  const handleMentionPressIn = useMentionHandler(onMentionPressIn);
  const handleMentionPressOut = useMentionHandler(onMentionPressOut);
  const handleMentionPress = useMentionHandler(onMentionPress);
  const handleMentionLongPress = useMentionHandler(onMentionLongPress);

  if (Platform.OS !== 'android' && Platform.OS !== 'ios') {
    return (
      <Text
        style={style}
        numberOfLines={numberOfLines}
        ellipsizeMode={ellipsizeMode}
        selectable={selectable}
        selectionColor={selectionColor}
        allowFontScaling={allowFontScaling}
        {...(rest as TextProps)}
      >
        {stripHtml(children)}
      </Text>
    );
  }

  return (
    <EnrichedTextViewNativeComponent
      text={children}
      style={style}
      htmlStyle={normalizedHtmlStyle}
      numberOfLines={numberOfLines}
      ellipsizeMode={ellipsizeMode}
      selectable={selectable}
      selectionColor={selectionColor}
      allowFontScaling={allowFontScaling}
      pressableLinks={
        !!(onLinkPressIn || onLinkPressOut || onLinkPress || onLinkLongPress)
      }
      pressableMentions={
        !!(
          onMentionPressIn ||
          onMentionPressOut ||
          onMentionPress ||
          onMentionLongPress
        )
      }
      longPressableLinks={!!onLinkLongPress}
      longPressableMentions={!!onMentionLongPress}
      onLinkPressIn={handleLinkPressIn}
      onLinkPressOut={handleLinkPressOut}
      onLinkPress={handleLinkPress}
      onLinkLongPress={handleLinkLongPress}
      onMentionPressIn={handleMentionPressIn}
      onMentionPressOut={handleMentionPressOut}
      onMentionPress={handleMentionPress}
      onMentionLongPress={handleMentionLongPress}
      {...rest}
    />
  );
};
