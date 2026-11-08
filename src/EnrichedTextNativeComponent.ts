import { codegenNativeComponent } from 'react-native';
import type {
  CodegenTypes,
  ColorValue,
  HostComponent,
  ViewProps,
} from 'react-native';

export interface OnLinkPressEvent {
  url: string;
}

export interface OnMentionPressEventInternal {
  text: string;
  indicator: string;
  type: string;
  attributes: CodegenTypes.UnsafeMixed;
}

export interface OnMentionPressEvent {
  text: string;
  indicator: string;
  type: string;
  attributes: Record<string, string>;
}

export interface NativeProps extends ViewProps {
  text: string;
  htmlStyle?: CodegenTypes.UnsafeMixed;
  numberOfLines?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
  ellipsizeMode?: CodegenTypes.WithDefault<string, 'tail'>;
  selectable?: CodegenTypes.WithDefault<boolean, false>;
  selectionColor?: ColorValue;
  allowFontScaling?: CodegenTypes.WithDefault<boolean, true>;
  pressableLinks?: CodegenTypes.WithDefault<boolean, false>;
  pressableMentions?: CodegenTypes.WithDefault<boolean, false>;
  longPressableLinks?: CodegenTypes.WithDefault<boolean, false>;
  longPressableMentions?: CodegenTypes.WithDefault<boolean, false>;

  onLinkPressIn?: CodegenTypes.DirectEventHandler<OnLinkPressEvent>;
  onLinkPressOut?: CodegenTypes.DirectEventHandler<OnLinkPressEvent>;
  onLinkPress?: CodegenTypes.DirectEventHandler<OnLinkPressEvent>;
  onLinkLongPress?: CodegenTypes.DirectEventHandler<OnLinkPressEvent>;
  onMentionPressIn?: CodegenTypes.DirectEventHandler<OnMentionPressEventInternal>;
  onMentionPressOut?: CodegenTypes.DirectEventHandler<OnMentionPressEventInternal>;
  onMentionPress?: CodegenTypes.DirectEventHandler<OnMentionPressEventInternal>;
  onMentionLongPress?: CodegenTypes.DirectEventHandler<OnMentionPressEventInternal>;

  color?: ColorValue;
  fontSize?: CodegenTypes.Float;
  lineHeight?: CodegenTypes.Float;
  fontFamily?: string;
  fontWeight?: string;
  fontStyle?: string;
  borderWidth?: CodegenTypes.Float;
  borderColor?: ColorValue;
  borderTopEndRadius?: CodegenTypes.Float;
  borderBottomStartRadius?: CodegenTypes.Float;
  borderBottomEndRadius?: CodegenTypes.Float;
}

export default codegenNativeComponent<NativeProps>('EnrichedTextView', {
  interfaceOnly: true,
}) as HostComponent<NativeProps>;
