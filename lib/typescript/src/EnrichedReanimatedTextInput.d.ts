import { type ComponentProps } from 'react';
import { type OnScrollEvent } from './EnrichedTextInputNativeComponent';
import type { EnrichedTextInputInstance, EnrichedTextInputProps } from './types';
import { type AnimatedRef, type EventHandlerProcessed } from 'react-native-reanimated';
import type { NativeSyntheticEvent } from 'react-native';
declare const EnrichedReanimatedNativeComponent: import("react-native-reanimated/lib/typescript/createAnimatedComponent").AnimatedComponentType<Readonly<import("./EnrichedTextInputNativeComponent").NativeProps>, import("react-native").HostComponent<import("./EnrichedTextInputNativeComponent").NativeProps>>;
type Props = Omit<EnrichedTextInputProps, 'onScroll'> & Pick<ComponentProps<typeof EnrichedReanimatedNativeComponent>, 'animatedProps' | 'style'> & {
    onScroll?: EventHandlerProcessed<OnScrollEvent, never> | ((event: NativeSyntheticEvent<OnScrollEvent>) => void);
    ref?: AnimatedRef<EnrichedTextInputInstance>;
};
export declare const EnrichedReanimatedTextInput: ({ ref, autoFocus, editable, mentionIndicators, defaultValue, placeholder, placeholderTextColor, cursorColor, selectionColor, style, autoCapitalize, htmlStyle, onFocus, onBlur, onChangeText, onChangeHtml, onChangeState, onLinkDetected, onMentionDetected, onStartMention, onChangeMention, onEndMention, onChangeSelection, onColorChangeInSelection, onParagraphAlignmentChange, contentInsets, androidExperimentalSynchronousEvents, scrollEnabled, keyboardDismissMode, onScroll, ...rest }: Props) => import("react/jsx-runtime").JSX.Element;
export {};
//# sourceMappingURL=EnrichedReanimatedTextInput.d.ts.map