import { useCallback, type RefObject } from 'react';
import type {
  OnLinkDetected,
  OnMentionDetected,
  OnMentionDetectedInternal,
  OnMentionEvent,
  OnRequestHtmlResultEvent,
} from '../../EnrichedTextInputNativeComponent';
import type { OnChangeMentionEvent } from '../../types';
import type { NativeSyntheticEvent } from 'react-native';

type Props = {
  onStartMention?: (indicator: string) => void;
  onChangeMention?: (event: OnChangeMentionEvent) => void;
  onEndMention?: (indicator: string) => void;
  onLinkDetected?: (event: OnLinkDetected) => void;
  onMentionDetected?: (event: OnMentionDetected) => void;
  pendingHtmlRequests: RefObject<
    Map<
      number,
      {
        resolve: (html: string) => void;
        reject: (error: Error) => void;
      }
    >
  >;
};

const useHandlers = ({
  onStartMention,
  onChangeMention,
  onEndMention,
  onLinkDetected,
  onMentionDetected,
  pendingHtmlRequests,
}: Props) => {
  const handleMentionEvent = useCallback(
    (e: NativeSyntheticEvent<OnMentionEvent>) => {
      const mentionText = e.nativeEvent.text;
      const mentionIndicator = e.nativeEvent.indicator;

      if (typeof mentionText === 'string') {
        if (mentionText === '') {
          onStartMention?.(mentionIndicator);
        } else {
          onChangeMention?.({ indicator: mentionIndicator, text: mentionText });
        }
      } else if (mentionText === null) {
        onEndMention?.(mentionIndicator);
      }
    },
    [onStartMention, onChangeMention, onEndMention]
  );

  const handleLinkDetected = useCallback(
    (e: NativeSyntheticEvent<OnLinkDetected>) => {
      const { text, url, start, end } = e.nativeEvent;
      onLinkDetected?.({ text, url, start, end });
    },
    [onLinkDetected]
  );

  const handleMentionDetected = useCallback(
    (e: NativeSyntheticEvent<OnMentionDetectedInternal>) => {
      const { text, indicator, payload } = e.nativeEvent;
      const attributes = JSON.parse(payload) as Record<string, string>;
      onMentionDetected?.({ text, indicator, attributes });
    },
    [onMentionDetected]
  );

  const handleRequestHtmlResult = useCallback(
    (e: NativeSyntheticEvent<OnRequestHtmlResultEvent>) => {
      const { requestId, html } = e.nativeEvent;
      const pending = pendingHtmlRequests.current.get(requestId);
      if (!pending) return;

      if (html === null || typeof html !== 'string') {
        pending.reject(new Error('Failed to parse HTML'));
      } else {
        pending.resolve(html);
      }

      pendingHtmlRequests.current.delete(requestId);
    },
    [pendingHtmlRequests]
  );

  return {
    handleMentionEvent,
    handleLinkDetected,
    handleMentionDetected,
    handleRequestHtmlResult,
  };
};

export { useHandlers };
