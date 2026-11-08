import type { CodegenTypes, ColorValue, HostComponent, ViewProps } from 'react-native';
export interface OnLinkPressEvent {
    url: string;
}
export interface OnMentionPressEventInternal {
    text: string;
    indicator: string;
    type: string;
    attributes: CodegenTypes.UnsafeMixed;
}
export interface NativeProps extends ViewProps {
    text: string;
    htmlStyle?: CodegenTypes.UnsafeMixed;
    numberOfLines?: CodegenTypes.WithDefault<CodegenTypes.Int32, 0>;
    ellipsizeMode?: CodegenTypes.WithDefault<string, 'tail'>;
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
}
declare const _default: HostComponent<NativeProps>;
export default _default;
//# sourceMappingURL=EnrichedTextLabelNativeComponent.d.ts.map