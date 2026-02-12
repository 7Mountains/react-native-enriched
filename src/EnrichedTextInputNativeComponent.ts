import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import type {
  DirectEventHandler,
  Float,
  Int32,
  UnsafeMixed,
} from 'react-native/Libraries/Types/CodegenTypes';
import type {
  ColorValue,
  HostComponent,
  TextStyle,
  ViewProps,
} from 'react-native';
import React from 'react';

export interface OnChangeTextEvent {
  value: string;
}

export interface OnChangeHtmlEvent {
  value: string;
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
  h2: { isActive: boolean; isConflicting: boolean; canNotBeApplied: boolean };
  h3: { isActive: boolean; isConflicting: boolean; canNotBeApplied: boolean };
  h4: { isActive: boolean; isConflicting: boolean; canNotBeApplied: boolean };
  h5: { isActive: boolean; isConflicting: boolean; canNotBeApplied: boolean };
  h6: { isActive: boolean; isConflicting: boolean; canNotBeApplied: boolean };
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
}

export interface OnLinkDetected {
  text: string;
  url: string;
  start: Int32;
  end: Int32;
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
  text: UnsafeMixed;
}

export interface OnChangeSelectionEvent {
  start: Int32;
  end: Int32;
  text: string;
}

export interface OnRequestHtmlResultEvent {
  requestId: Int32;
  html: UnsafeMixed;
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
  fontSize?: Float;
  bold?: boolean;
};

export interface ContentStyleProperties {
  textColor?: ColorValue;
  borderStyle?: 'solid' | 'dashed' | 'dotted';
  borderRadius?: number;
  backgroundColor?: ColorValue;
  borderWidth?: number;
  borderColor?: ColorValue;
  paddingTop?: number;
  paddingBottom?: number;
  paddingRight?: number;
  paddingLeft?: number;
  marginLeft?: number;
  marginRight?: number;
  marginTop?: number;
  marginBottom?: number;
  imageBorderRadiusTopLeft?: number;
  imageBorderRadiusTopRight?: number;
  imageBorderRadiusBottomRight?: number;
  imageBorderRadiusBottomLeft?: number;
  imageWidth?: number;
  imageHeight?: number;
  imageResizeMode?:
    | 'contain'
    | 'fill'
    | 'cover'
    | 'stretch'
    | 'center'
    | 'none'
    | 'scale-down';
  fontSize?: number;
  fontWeight?: TextStyle['fontWeight'];
  fallbackImageURI?: string;
  width?: number;
  height?: number;
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
    borderWidth?: Float;
    gapWidth?: Float;
    color?: ColorValue;
  };
  codeblock?: {
    color?: ColorValue;
    borderRadius?: Float;
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
  // This is a workaround for the fact that codegen does not support Records.
  // On native Android side this will become a ReadableMap, on native iOS we can work with a folly::dynamic object.
  mention?: UnsafeMixed;
  content?: UnsafeMixed;
  img?: {
    width?: Float;
    height?: Float;
  };
  ol?: {
    gapWidth?: Float;
    marginLeft?: Float;
    markerFontWeight?: string;
    markerColor?: ColorValue;
  };
  ul?: {
    bulletColor?: ColorValue;
    bulletSize?: Float;
    marginLeft?: Float;
    gapWidth?: Float;
  };
  checkbox?: {
    imageWidth?: Float;
    imageHeight?: Float;
    checkedImage?: string;
    uncheckedImage?: string;
    marginLeft?: Float;
    gapWidth?: Float;
    checkedTextColor?: ColorValue;
  };
  divider?: {
    height?: Float;
    color?: ColorValue;
    thickness?: Float;
  };
}

export interface OnScrollEvent {
  contentInset: {
    top: Float;
    bottom: Float;
    left: Float;
    right: Float;
  };
  contentOffset: {
    x: Float;
    y: Float;
  };
  contentSize: {
    width: Float;
    height: Float;
  };
  layoutMeasurement: {
    width: Float;
    height: Float;
  };
  velocity: {
    x: Float;
    y: Float;
  };
  target: Int32;
}

export type Insets = {
  top: Float;
  left: Float;
  bottom: Float;
  right: Float;
};

export interface Cookie {
  domain: string;
  name: string;
  value: string;
}

export interface NativeProps extends ViewProps {
  // base props
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
  keyboardDismissMode?: string;
  iOSparagraphSpacing?: Float;
  iOSparagraphSpacingBefore?: Float;

  // event callbacks
  onInputFocus?: DirectEventHandler<null>;
  onInputBlur?: DirectEventHandler<null>;
  onChangeText?: DirectEventHandler<OnChangeTextEvent>;
  onChangeHtml?: DirectEventHandler<OnChangeHtmlEvent>;
  onChangeState?: DirectEventHandler<OnChangeStateEvent>;
  onLinkDetected?: DirectEventHandler<OnLinkDetected>;
  onMentionDetected?: DirectEventHandler<OnMentionDetectedInternal>;
  onMention?: DirectEventHandler<OnMentionEvent>;
  onChangeSelection?: DirectEventHandler<OnChangeSelectionEvent>;
  onRequestHtmlResult?: DirectEventHandler<OnRequestHtmlResultEvent>;
  onColorChangeInSelection?: DirectEventHandler<OnChangeColorEvent>;
  onParagraphAlignmentChange?: DirectEventHandler<OnParagraphAlignmentChangeEvent>;
  onInputScroll?: DirectEventHandler<OnScrollEvent>;

  // Style related props - used for generating proper setters in component's manager
  // These should not be passed as regular props
  color?: ColorValue;
  fontSize?: Float;
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;

  // Used for onChangeHtml event performance optimization
  isOnChangeHtmlSet: boolean;
  // Used for onChangeText event performance optimization
  isOnChangeTextSet: boolean;
  // used for onScroll event performance optimization
  isOnScrollSet: boolean;

  contentInsets?: Insets;
  scrollIndicatorInsets?: Insets;
  automaticallyAdjustsScrollIndicatorInsets?: boolean;
  automaticallyAdjustContentInsets?: boolean;

  // Experimental
  androidExperimentalSynchronousEvents: boolean;
  loaderCookies?: Cookie[];
}

type ComponentType = HostComponent<NativeProps>;

interface NativeCommands {
  // General commands
  focus: (viewRef: React.ElementRef<ComponentType>) => void;
  blur: (viewRef: React.ElementRef<ComponentType>) => void;
  setValue: (viewRef: React.ElementRef<ComponentType>, text: string) => void;
  setSelection: (
    viewRef: React.ElementRef<ComponentType>,
    start: Int32,
    end: Int32
  ) => void;

  // Text formatting commands
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
  addLink: (
    viewRef: React.ElementRef<ComponentType>,
    start: Int32,
    end: Int32,
    text: string,
    url: string
  ) => void;
  addImage: (
    viewRef: React.ElementRef<ComponentType>,
    uri: string,
    width: Float,
    height: Float
  ) => void;
  startMention: (
    viewRef: React.ElementRef<ComponentType>,
    indicator: string
  ) => void;
  addMention: (
    viewRef: React.ElementRef<ComponentType>,
    indicator: string,
    text: string,
    type: string,
    payload: string
  ) => void;
  requestHTML: (
    viewRef: React.ElementRef<ComponentType>,
    requestId: Int32,
    prettify: boolean
  ) => void;
  toggleCheckList: (viewRef: React.ElementRef<ComponentType>) => void;
  setColor: (viewRef: React.ElementRef<ComponentType>, color: string) => void;
  removeColor: (viewRef: React.ElementRef<ComponentType>) => void;
  addDividerAtNewLine: (viewRef: React.ElementRef<ComponentType>) => void;
  setParagraphAlignment: (
    viewRef: React.ElementRef<ComponentType>,
    alignment: string
  ) => void;
  scrollTo: (
    viewRef: React.ElementRef<ComponentType>,
    x: Float,
    y: Float,
    animated: boolean
  ) => void;
  addContent: (
    viewRef: React.ElementRef<ComponentType>,
    text: string,
    type: string,
    src: string,
    attributes: string
  ) => void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    // General commands
    'focus',
    'blur',
    'setValue',
    'setSelection',

    // Text formatting commands
    'toggleBold',
    'toggleItalic',
    'toggleUnderline',
    'toggleStrikeThrough',
    'toggleInlineCode',
    'toggleH1',
    'toggleH2',
    'toggleH3',
    'toggleH4',
    'toggleH5',
    'toggleH6',
    'toggleCodeBlock',
    'toggleBlockQuote',
    'toggleOrderedList',
    'toggleUnorderedList',
    'addLink',
    'addImage',
    'startMention',
    'addMention',
    'requestHTML',
    'toggleCheckList',
    'setColor',
    'removeColor',
    'addDividerAtNewLine',
    'setParagraphAlignment',
    'scrollTo',
    'addContent',
  ],
});

export default codegenNativeComponent<NativeProps>('EnrichedTextInputView', {
  interfaceOnly: true,
}) as HostComponent<NativeProps>;
