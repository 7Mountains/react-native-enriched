"use strict";

import { useCallback } from 'react';
const useHandlers = ({
  onStartMention,
  onChangeMention,
  onEndMention,
  onLinkDetected,
  onMentionDetected,
  pendingHtmlRequests
}) => {
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
  }, [pendingHtmlRequests]);
  return {
    handleMentionEvent,
    handleLinkDetected,
    handleMentionDetected,
    handleRequestHtmlResult
  };
};
export { useHandlers };
//# sourceMappingURL=index.js.map