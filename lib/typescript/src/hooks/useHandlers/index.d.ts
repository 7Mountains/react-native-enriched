import { type RefObject } from 'react';
import type { OnLinkDetected, OnMentionDetected, OnMentionDetectedInternal, OnMentionEvent, OnRequestHtmlResultEvent } from '../../EnrichedTextInputNativeComponent';
import type { OnChangeMentionEvent, HtmlRequest } from '../../types';
import type { NativeSyntheticEvent } from 'react-native';
type Props = {
    onStartMention?: (indicator: string) => void;
    onChangeMention?: (event: OnChangeMentionEvent) => void;
    onEndMention?: (indicator: string) => void;
    onLinkDetected?: (event: OnLinkDetected) => void;
    onMentionDetected?: (event: OnMentionDetected) => void;
    pendingHtmlRequests: RefObject<Map<number, HtmlRequest>>;
};
declare const useHandlers: ({ onStartMention, onChangeMention, onEndMention, onLinkDetected, onMentionDetected, pendingHtmlRequests, }: Props) => {
    handleMentionEvent: (e: NativeSyntheticEvent<OnMentionEvent>) => void;
    handleLinkDetected: (e: NativeSyntheticEvent<OnLinkDetected>) => void;
    handleMentionDetected: (e: NativeSyntheticEvent<OnMentionDetectedInternal>) => void;
    handleRequestHtmlResult: (e: NativeSyntheticEvent<OnRequestHtmlResultEvent>) => void;
};
export { useHandlers };
//# sourceMappingURL=index.d.ts.map