import type { ColorValue, ImageRequireSource, NativeMethods, NativeSyntheticEvent, TextStyle, ViewProps, ViewStyle } from 'react-native';
import type { ContentStyleProperties, Insets, Cookie, MentionStyleProperties, NativeProps, OnChangeColorEvent, OnChangeHtmlEvent, OnChangeSelectionEvent, OnChangeStateEvent, OnChangeTextEvent, OnLinkDetected, OnMentionDetected, OnParagraphAlignmentChangeEvent, OnScrollEvent, CheckboxPressEvent } from './EnrichedTextInputNativeComponent';
import type { Component, RefObject } from 'react';
export interface EnrichedTextInputInstance extends NativeMethods {
    focus: () => void;
    blur: () => void;
    setValue: (value: string) => void;
    setSelection: (start: number, end: number) => void;
    getHTML: (prettify?: boolean) => Promise<string>;
    toggleBold: () => void;
    toggleItalic: () => void;
    toggleUnderline: () => void;
    toggleStrikeThrough: () => void;
    toggleInlineCode: () => void;
    toggleH1: () => void;
    toggleH2: () => void;
    toggleH3: () => void;
    toggleH4: () => void;
    toggleH5: () => void;
    toggleH6: () => void;
    toggleCodeBlock: () => void;
    toggleBlockQuote: () => void;
    toggleOrderedList: () => void;
    toggleUnorderedList: () => void;
    setLink: (start: number, end: number, text: string, url: string) => void;
    setImage: (src: string, width: number, height: number) => void;
    startMention: (indicator: string) => void;
    setMention: (indicator: string, text: string, type: string, attributes?: Record<string, string>) => void;
    toggleCheckList: () => void;
    setColor: (color: string) => void;
    removeColor: () => void;
    addDividerAtNewLine: () => void;
    setParagraphAlignment: (alignment: string) => void;
    scrollTo: (x: number, y: number, animated?: boolean) => void;
    addContent: (text: string, type: string, src: string, attributes: string) => void;
}
export interface OnChangeMentionEvent {
    indicator: string;
    text: string;
}
type HeadingStyle = {
    fontSize?: number;
    bold?: boolean;
};
export interface HtmlStyle {
    h1?: HeadingStyle;
    h2?: HeadingStyle;
    h3?: HeadingStyle;
    h4?: HeadingStyle;
    h5?: HeadingStyle;
    h6?: HeadingStyle;
    blockquote?: {
        borderColor?: ColorValue;
        borderWidth?: number;
        gapWidth?: number;
        color?: ColorValue;
    };
    codeblock?: {
        color?: ColorValue;
        borderRadius?: number;
        backgroundColor?: ColorValue;
    };
    code?: {
        color?: ColorValue;
        backgroundColor?: ColorValue;
    };
    a?: {
        color?: ColorValue;
        textDecorationLine?: 'underline' | 'none';
    };
    mention?: Record<string, MentionStyleProperties> | MentionStyleProperties;
    content?: Record<string, ContentStyleProperties> | ContentStyleProperties;
    img?: {
        width?: number;
        height?: number;
    };
    ol?: {
        gapWidth?: number;
        marginLeft?: number;
        markerFontWeight?: TextStyle['fontWeight'];
        markerColor?: ColorValue;
    };
    ul?: {
        bulletColor?: ColorValue;
        bulletSize?: number;
        marginLeft?: number;
        gapWidth?: number;
    };
    checkbox?: {
        imageWidth?: number;
        imageHeight?: number;
        checkedImage?: ImageRequireSource;
        uncheckedImage?: ImageRequireSource;
        marginLeft?: number;
        gapWidth?: number;
        checkedTextColor?: ColorValue;
    };
    divider?: {
        height?: number;
        color?: ColorValue;
        thickness?: number;
    };
}
export interface EnrichedTextInputProps extends Omit<ViewProps, 'children'> {
    ref?: RefObject<EnrichedTextInputInstance | null>;
    autoFocus?: boolean;
    automaticallyAdjustsScrollIndicatorInsets?: boolean;
    automaticallyAdjustContentInsets?: boolean;
    editable?: boolean;
    mentionIndicators?: string[];
    defaultValue?: string;
    placeholder?: string;
    placeholderTextColor?: ColorValue;
    cursorColor?: ColorValue;
    selectionColor?: ColorValue;
    autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
    htmlStyle?: HtmlStyle;
    style?: ViewStyle | TextStyle;
    scrollEnabled?: boolean;
    keyboardDismissMode?: 'none' | 'interactive' | 'on-drag';
    iOSparagraphSpacing?: number;
    iOSparagraphSpacingBefore?: number;
    onFocus?: () => void;
    onBlur?: () => void;
    onChangeText?: (e: NativeSyntheticEvent<OnChangeTextEvent>) => void;
    onChangeHtml?: (e: NativeSyntheticEvent<OnChangeHtmlEvent>) => void;
    onChangeState?: (e: NativeSyntheticEvent<OnChangeStateEvent>) => void;
    onLinkDetected?: (e: OnLinkDetected) => void;
    onMentionDetected?: (e: OnMentionDetected) => void;
    onStartMention?: (indicator: string) => void;
    onChangeMention?: (e: OnChangeMentionEvent) => void;
    onEndMention?: (indicator: string) => void;
    onChangeSelection?: (e: NativeSyntheticEvent<OnChangeSelectionEvent>) => void;
    onColorChangeInSelection?: (color: NativeSyntheticEvent<OnChangeColorEvent>) => void;
    onParagraphAlignmentChange?: (e: NativeSyntheticEvent<OnParagraphAlignmentChangeEvent>) => void;
    onCheckboxPress?: (e: NativeSyntheticEvent<CheckboxPressEvent>) => void;
    /**
     * If true, Android will use experimental synchronous events.
     * This will prevent from input flickering when updating component size.
     * However, this is an experimental feature, which has not been thoroughly tested.
     * We may decide to enable it by default in a future release.
     * Disabled by default.
     */
    androidExperimentalSynchronousEvents?: boolean;
    contentInsets?: Insets;
    scrollIndicatorInsets?: Insets;
    onScroll?: (event: NativeSyntheticEvent<OnScrollEvent>) => void;
    loaderCookies?: Cookie[];
}
export type ComponentType = (Component<NativeProps, {}, any> & NativeMethods) | null;
export type HtmlRequest = {
    resolve: (html: string) => void;
    reject: (error: Error) => void;
};
export {};
//# sourceMappingURL=types.d.ts.map