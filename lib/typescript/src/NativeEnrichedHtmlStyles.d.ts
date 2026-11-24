import { type TurboModule } from 'react-native';
export interface Spec extends TurboModule {
    /**
     * Registers a normalized html style, shared by the texts showing it
     *
     * @param style - The normalized style (see `normalizeHtmlStyle`)
     * @returns The id the texts pass instead of the style
     */
    registerHtmlStyle(style: Object): number;
}
declare const _default: Spec | null | undefined;
export default _default;
//# sourceMappingURL=NativeEnrichedHtmlStyles.d.ts.map