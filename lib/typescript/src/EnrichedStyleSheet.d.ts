import type { HtmlStyle } from './types';
/**
 * The styles of the enriched components made once, outside of the render, as
 * React Native's `StyleSheet`
 */
export declare const EnrichedStyleSheet: {
    /**
     * An html style ready for the enriched components as it's made:
     * `EnrichedText` takes it by its registered id and `EnrichedTextInput` by
     * its normalized form, neither converts it while rendering. Frozen: changed
     * after, its registered id wouldn't follow it.
     *
     * @param style - The html style
     * @returns The same style, frozen
     */
    createHtmlStyle<T extends HtmlStyle>(style: T): Readonly<T>;
};
//# sourceMappingURL=EnrichedStyleSheet.d.ts.map