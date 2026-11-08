"use strict";

import { useMemo } from 'react';
import { Platform, Text } from 'react-native';
import EnrichedTextNativeComponent from './EnrichedTextNativeComponent';
import { normalizeHtmlStyle } from "./normalizeHtmlStyle.js";
import { jsx as _jsx } from "react/jsx-runtime";
const EMPTY_HTML_STYLE = {};
const HTML_ENTITIES = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#39;': "'",
  '&nbsp;': ' '
};

/**
 * The text of the HTML, for the platforms without the native component yet
 *
 * @param html - The HTML, or plain text
 * @returns The text without the markup
 */
const stripHtml = html => html.replace(/<\/(p|h[1-6]|li|blockquote|codeblock)>|<br\s*\/?>/gi, '\n').replace(/<[^>]+>/g, '').replace(/&(amp|lt|gt|quot|#39|nbsp);/g, entity => HTML_ENTITIES[entity]).trim();

/**
 * The native handler of a link event, only when the event is listened to
 *
 * @param handler - The handler of the event
 * @returns The native handler, or undefined
 */
const useLinkHandler = handler => useMemo(() => handler ? ({
  nativeEvent
}) => handler(nativeEvent) : undefined, [handler]);

/**
 * The native handler of a mention event, only when the event is listened to
 *
 * @param handler - The handler of the event
 * @returns The native handler, or undefined
 */
const useMentionHandler = handler => useMemo(() => handler ? ({
  nativeEvent: {
    text,
    indicator,
    type,
    attributes
  }
}) => handler({
  text,
  indicator,
  type,
  attributes: attributes
}) : undefined, [handler]);

/**
 * Shows the HTML of `EnrichedTextInput`, natively laid out and measured with
 * the same styles as the input. On the other platforms than Android and iOS it
 * shows the text without its markup.
 *
 * @param props - The component props
 * @returns The text
 */
export const EnrichedText = ({
  children,
  style,
  htmlStyle = EMPTY_HTML_STYLE,
  numberOfLines = 0,
  ellipsizeMode = 'tail',
  selectable = false,
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
}) => {
  const normalizedHtmlStyle = useMemo(() => normalizeHtmlStyle(htmlStyle), [htmlStyle]);
  const handleLinkPressIn = useLinkHandler(onLinkPressIn);
  const handleLinkPressOut = useLinkHandler(onLinkPressOut);
  const handleLinkPress = useLinkHandler(onLinkPress);
  const handleLinkLongPress = useLinkHandler(onLinkLongPress);
  const handleMentionPressIn = useMentionHandler(onMentionPressIn);
  const handleMentionPressOut = useMentionHandler(onMentionPressOut);
  const handleMentionPress = useMentionHandler(onMentionPress);
  const handleMentionLongPress = useMentionHandler(onMentionLongPress);
  if (Platform.OS !== 'android' && Platform.OS !== 'ios') {
    return /*#__PURE__*/_jsx(Text, {
      style: style,
      numberOfLines: numberOfLines,
      ellipsizeMode: ellipsizeMode,
      selectable: selectable,
      selectionColor: selectionColor,
      allowFontScaling: allowFontScaling,
      ...rest,
      children: stripHtml(children)
    });
  }
  return /*#__PURE__*/_jsx(EnrichedTextNativeComponent, {
    text: children,
    style: style,
    htmlStyle: normalizedHtmlStyle,
    numberOfLines: numberOfLines,
    ellipsizeMode: ellipsizeMode,
    selectable: selectable,
    selectionColor: selectionColor,
    allowFontScaling: allowFontScaling,
    pressableLinks: !!(onLinkPressIn || onLinkPressOut || onLinkPress || onLinkLongPress),
    pressableMentions: !!(onMentionPressIn || onMentionPressOut || onMentionPress || onMentionLongPress),
    longPressableLinks: !!onLinkLongPress,
    longPressableMentions: !!onMentionLongPress,
    onLinkPressIn: handleLinkPressIn,
    onLinkPressOut: handleLinkPressOut,
    onLinkPress: handleLinkPress,
    onLinkLongPress: handleLinkLongPress,
    onMentionPressIn: handleMentionPressIn,
    onMentionPressOut: handleMentionPressOut,
    onMentionPress: handleMentionPress,
    onMentionLongPress: handleMentionLongPress,
    ...rest
  });
};
//# sourceMappingURL=EnrichedText.js.map