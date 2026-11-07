import type { CodegenTypes, ColorValue, HostComponent, ViewProps } from 'react-native';
import React from 'react';
export interface OnChangeTextEvent {
    value: string;
}
export interface OnChangeHtmlEvent {
    value: string;
}
export interface CheckboxPressEvent {
    isChecked: boolean;
}
export interface OnChangeStateEvent {
    alignment: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    bold: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    italic: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    underline: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    strikeThrough: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    inlineCode: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    h1: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    h2: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    h3: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    h4: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    h5: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    h6: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    codeBlock: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    blockQuote: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    orderedList: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    unorderedList: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    link: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    image: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    mention: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    checkList: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    colored: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    content: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
    mdf: {
        isActive: boolean;
        isConflicting: boolean;
        canNotBeApplied: boolean;
    };
}
export interface OnLinkDetected {
    text: string;
    url: string;
    start: CodegenTypes.Int32;
    end: CodegenTypes.Int32;
}
export interface OnMentionDetectedInternal {
    text: string;
    indicator: string;
    payload: string;
}
export interface OnMentionDetected {
    text: string;
    indicator: string;
    attributes: Record<string, string>;
}
export interface OnMentionEvent {
    indicator: string;
    text: CodegenTypes.UnsafeMixed;
}
export interface OnChangeSelectionEvent {
    start: CodegenTypes.Int32;
    end: CodegenTypes.Int32;
    text: string;
    paragraphStart: CodegenTypes.Int32;
    paragraphEnd: CodegenTypes.Int32;
}
export interface OnRequestHtmlResultEvent {
    requestId: CodegenTypes.Int32;
    html: CodegenTypes.UnsafeMixed;
}
export interface MentionStyleProperties {
    color?: ColorValue;
    backgroundColor?: ColorValue;
    textDecorationLine?: 'underline' | 'none';
}
export interface OnChangeColorEvent {
    color: string | null;
}
export interface OnParagraphAlignmentChangeEvent {
    alignment: string;
}
type Heading = {
    fontSize?: CodegenTypes.Float;
    bold?: boolean;
};
interface ContentTextStyle {
    color?: ColorValue;
    fontWeight?: string;
    fontSize?: CodegenTypes.Float;
    fontFamily?: string;
    marginTop?: CodegenTypes.Float;
    marginBottom?: CodegenTypes.Float;
    marginRight?: CodegenTypes.Float;
    marginLeft?: CodegenTypes.Float;
}
interface ContentContainerStyle {
    minHeight?: CodegenTypes.Float;
    borderWidth?: CodegenTypes.Float;
    borderColor?: ColorValue;
    paddingTop?: CodegenTypes.Float;
    paddingBottom?: CodegenTypes.Float;
    paddingRight?: CodegenTypes.Float;
    paddingLeft?: CodegenTypes.Float;
    marginLeft?: CodegenTypes.Float;
    marginRight?: CodegenTypes.Float;
    marginTop?: CodegenTypes.Float;
    marginBottom?: CodegenTypes.Float;
    backgroundColor?: ColorValue;
    borderStyle?: string;
    borderRadius?: CodegenTypes.Float;
    borderLeftWidth?: CodegenTypes.Float;
}
export interface ContentImageContainerStyle {
    width?: CodegenTypes.Float;
    height?: CodegenTypes.Float;
    borderRadius?: CodegenTypes.Float;
    backgroundColor?: ColorValue;
}
export interface ContentImageStyle {
    width?: CodegenTypes.Float;
    height?: CodegenTypes.Float;
    resizeMode?: string;
}
export interface ContentTextContainerStyle {
    paddingTop?: CodegenTypes.Float;
    paddingBottom?: CodegenTypes.Float;
    paddingRight?: CodegenTypes.Float;
    paddingLeft?: CodegenTypes.Float;
    marginLeft?: CodegenTypes.Float;
    marginRight?: CodegenTypes.Float;
    marginTop?: CodegenTypes.Float;
    marginBottom?: CodegenTypes.Float;
}
export interface ContentStyleProperties {
    title?: ContentTextStyle;
    description?: ContentTextStyle;
    subtitle?: ContentTextStyle;
    subDescription?: ContentTextStyle;
    container?: ContentContainerStyle;
    textContainer?: ContentTextContainerStyle;
    imageContainer?: ContentImageContainerStyle;
    image?: ContentImageStyle;
    fallbackImageURI?: string;
}
export interface HtmlStyleInternal {
    h1?: Heading;
    h2?: Heading;
    h3?: Heading;
    h4?: Heading;
    h5?: Heading;
    h6?: Heading;
    blockquote?: {
        borderColor?: ColorValue;
        borderWidth?: CodegenTypes.Float;
        gapWidth?: CodegenTypes.Float;
        color?: ColorValue;
    };
    codeblock?: {
        color?: ColorValue;
        borderRadius?: CodegenTypes.Float;
        backgroundColor?: ColorValue;
    };
    code?: {
        color?: ColorValue;
        backgroundColor?: ColorValue;
    };
    a?: {
        color?: ColorValue;
        textDecorationLine?: string;
    };
    mention?: CodegenTypes.UnsafeMixed;
    content?: CodegenTypes.UnsafeMixed;
    img?: {
        width?: CodegenTypes.Float;
        height?: CodegenTypes.Float;
    };
    ol?: {
        gapWidth?: CodegenTypes.Float;
        marginLeft?: CodegenTypes.Float;
        markerFontWeight?: string;
        markerColor?: ColorValue;
    };
    ul?: {
        bulletColor?: ColorValue;
        bulletSize?: CodegenTypes.Float;
        marginLeft?: CodegenTypes.Float;
        gapWidth?: CodegenTypes.Float;
    };
    checkbox?: {
        imageWidth?: CodegenTypes.Float;
        imageHeight?: CodegenTypes.Float;
        marginLeft?: CodegenTypes.Float;
        gapWidth?: CodegenTypes.Float;
        checkedTextColor?: ColorValue;
    };
    divider?: {
        height?: CodegenTypes.Float;
        color?: ColorValue;
        thickness?: CodegenTypes.Float;
    };
    mdf?: {
        imageUri: string;
        title: ContentTextStyle;
        container?: ContentContainerStyle;
        imageContainer?: ContentImageContainerStyle;
        textContainer?: ContentTextContainerStyle;
        image?: ContentImageStyle;
    };
}
export interface OnScrollEvent {
    contentInset: {
        top: CodegenTypes.Float;
        bottom: CodegenTypes.Float;
        left: CodegenTypes.Float;
        right: CodegenTypes.Float;
    };
    contentOffset: {
        x: CodegenTypes.Float;
        y: CodegenTypes.Float;
    };
    contentSize: {
        width: CodegenTypes.Float;
        height: CodegenTypes.Float;
    };
    layoutMeasurement: {
        width: CodegenTypes.Float;
        height: CodegenTypes.Float;
    };
    velocity: {
        x: CodegenTypes.Float;
        y: CodegenTypes.Float;
    };
    target: CodegenTypes.Int32;
}
export type Insets = {
    top: CodegenTypes.Float;
    left: CodegenTypes.Float;
    bottom: CodegenTypes.Float;
    right: CodegenTypes.Float;
};
export interface Cookie {
    domain: string;
    name: string;
    value: string;
}
export interface OnKeyPressEvent {
    key: string;
    selection: {
        start: CodegenTypes.Int32;
        end: CodegenTypes.Int32;
    };
}
export interface ContextMenuItemConfig {
    text: string;
    key: string;
    iOSIcon?: string;
}
export interface OnContextMenuItemPressEvent {
    text: string;
    key: string;
    selection: {
        start: CodegenTypes.Int32;
        end: CodegenTypes.Int32;
    };
}
export interface NativeProps extends ViewProps {
    autoFocus?: boolean;
    editable?: boolean;
    defaultValue?: string;
    placeholder?: string;
    placeholderTextColor?: ColorValue;
    mentionIndicators: string[];
    cursorColor?: ColorValue;
    selectionColor?: ColorValue;
    autoCapitalize?: string;
    htmlStyle?: HtmlStyleInternal;
    scrollEnabled?: boolean;
    dragAndDropEnabled?: CodegenTypes.WithDefault<boolean, true>;
    keyboardDismissMode?: string;
    iOSparagraphSpacing?: CodegenTypes.Float;
    iOSparagraphSpacingBefore?: CodegenTypes.Float;
    paragraphsLimit?: CodegenTypes.Int32;
    stylesConfig?: string[];
    contextMenuItems?: Readonly<Array<ContextMenuItemConfig>>;
    writingToolsBehavior?: string;
    maxLength?: CodegenTypes.WithDefault<CodegenTypes.Int32, -1>;
    onInputFocus?: CodegenTypes.DirectEventHandler<null>;
    onInputBlur?: CodegenTypes.DirectEventHandler<null>;
    onChangeText?: CodegenTypes.DirectEventHandler<OnChangeTextEvent>;
    onChangeHtml?: CodegenTypes.DirectEventHandler<OnChangeHtmlEvent>;
    onChangeState?: CodegenTypes.DirectEventHandler<OnChangeStateEvent>;
    onLinkDetected?: CodegenTypes.DirectEventHandler<OnLinkDetected>;
    onMentionDetected?: CodegenTypes.DirectEventHandler<OnMentionDetectedInternal>;
    onMention?: CodegenTypes.DirectEventHandler<OnMentionEvent>;
    onChangeSelection?: CodegenTypes.DirectEventHandler<OnChangeSelectionEvent>;
    onRequestHtmlResult?: CodegenTypes.DirectEventHandler<OnRequestHtmlResultEvent>;
    onColorChangeInSelection?: CodegenTypes.DirectEventHandler<OnChangeColorEvent>;
    onParagraphAlignmentChange?: CodegenTypes.DirectEventHandler<OnParagraphAlignmentChangeEvent>;
    onInputScroll?: CodegenTypes.DirectEventHandler<OnScrollEvent>;
    onCheckboxPress?: CodegenTypes.DirectEventHandler<CheckboxPressEvent>;
    onAnyContentChange?: CodegenTypes.DirectEventHandler<null>;
    onInputKeyPress?: CodegenTypes.DirectEventHandler<OnKeyPressEvent>;
    onContextMenuItemPress?: CodegenTypes.DirectEventHandler<OnContextMenuItemPressEvent>;
    color?: ColorValue;
    fontSize?: CodegenTypes.Float;
    fontFamily?: string;
    fontWeight?: string;
    fontStyle?: string;
    lineHeight?: CodegenTypes.Float;
    borderLeftWidth?: CodegenTypes.Float;
    borderRightWidth?: CodegenTypes.Float;
    borderTopWidth?: CodegenTypes.Float;
    borderBottomWidth?: CodegenTypes.Float;
    borderStartWidth?: CodegenTypes.Float;
    borderEndWidth?: CodegenTypes.Float;
    borderColor?: ColorValue;
    borderLeftColor?: ColorValue;
    borderRightColor?: ColorValue;
    borderTopColor?: ColorValue;
    borderBottomColor?: ColorValue;
    borderStartColor?: ColorValue;
    borderEndColor?: ColorValue;
    borderBlockColor?: ColorValue;
    borderBlockStartColor?: ColorValue;
    borderBlockEndColor?: ColorValue;
    borderRadius?: CodegenTypes.Float;
    borderTopLeftRadius?: CodegenTypes.Float;
    borderTopRightRadius?: CodegenTypes.Float;
    borderBottomLeftRadius?: CodegenTypes.Float;
    borderBottomRightRadius?: CodegenTypes.Float;
    borderTopStartRadius?: CodegenTypes.Float;
    borderTopEndRadius?: CodegenTypes.Float;
    borderBottomStartRadius?: CodegenTypes.Float;
    borderBottomEndRadius?: CodegenTypes.Float;
    borderStartStartRadius?: CodegenTypes.Float;
    borderStartEndRadius?: CodegenTypes.Float;
    borderEndStartRadius?: CodegenTypes.Float;
    borderEndEndRadius?: CodegenTypes.Float;
    borderStyle?: string;
    borderWidth?: CodegenTypes.Float;
    isOnChangeHtmlSet: boolean;
    isOnChangeTextSet: boolean;
    isOnScrollSet: boolean;
    contentInsets?: Insets;
    scrollIndicatorInsets?: Insets;
    automaticallyAdjustsScrollIndicatorInsets?: boolean;
    automaticallyAdjustContentInsets?: boolean;
    bouncesVertically?: boolean;
    androidExperimentalSynchronousEvents: boolean;
    loaderCookies?: Cookie[];
}
type ComponentType = HostComponent<NativeProps>;
interface NativeCommands {
    focus: (viewRef: React.ElementRef<ComponentType>) => void;
    blur: (viewRef: React.ElementRef<ComponentType>) => void;
    setValue: (viewRef: React.ElementRef<ComponentType>, text: string) => void;
    setSelection: (viewRef: React.ElementRef<ComponentType>, start: CodegenTypes.Int32, end: CodegenTypes.Int32) => void;
    toggleBold: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleItalic: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleUnderline: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleStrikeThrough: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleInlineCode: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleH1: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleH2: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleH3: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleH4: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleH5: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleH6: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleCodeBlock: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleBlockQuote: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleOrderedList: (viewRef: React.ElementRef<ComponentType>) => void;
    toggleUnorderedList: (viewRef: React.ElementRef<ComponentType>) => void;
    addLink: (viewRef: React.ElementRef<ComponentType>, start: CodegenTypes.Int32, end: CodegenTypes.Int32, text: string, url: string) => void;
    removeLink: (viewRef: React.ElementRef<ComponentType>, start: CodegenTypes.Int32, end: CodegenTypes.Int32) => void;
    addImage: (viewRef: React.ElementRef<ComponentType>, uri: string, width: CodegenTypes.Float, height: CodegenTypes.Float) => void;
    startMention: (viewRef: React.ElementRef<ComponentType>, indicator: string) => void;
    addMention: (viewRef: React.ElementRef<ComponentType>, indicator: string, text: string, type: string, payload: string) => void;
    requestHTML: (viewRef: React.ElementRef<ComponentType>, requestId: CodegenTypes.Int32, prettify: boolean) => void;
    toggleCheckList: (viewRef: React.ElementRef<ComponentType>) => void;
    setColor: (viewRef: React.ElementRef<ComponentType>, color: string) => void;
    removeColor: (viewRef: React.ElementRef<ComponentType>) => void;
    addDividerAtNewLine: (viewRef: React.ElementRef<ComponentType>) => void;
    setParagraphAlignment: (viewRef: React.ElementRef<ComponentType>, alignment: string) => void;
    scrollTo: (viewRef: React.ElementRef<ComponentType>, x: CodegenTypes.Float, y: CodegenTypes.Float, animated: boolean) => void;
    addContent: (viewRef: React.ElementRef<ComponentType>, text: string, type: string, src: string, attributes: string) => void;
    insertTextAtSelection: (viewRef: React.ElementRef<ComponentType>, text: string) => void;
    insertText: (viewRef: React.ElementRef<ComponentType>, text: string, start: CodegenTypes.Int32 | null, end: CodegenTypes.Int32 | null) => void;
    hideContextMenu: (viewRef: React.ElementRef<ComponentType>) => void;
}
export declare const Commands: NativeCommands;
declare const _default: HostComponent<NativeProps>;
export default _default;
//# sourceMappingURL=EnrichedTextInputNativeComponent.d.ts.map