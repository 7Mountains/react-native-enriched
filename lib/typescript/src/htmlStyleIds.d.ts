import type { HtmlStyle } from './types';
/**
 * The id of the html style registered natively: the texts pass the id instead
 * of the style, which isn't converted and copied for every text.
 *
 * @param style - The html style
 * @returns The id of the style, 0 without the native module
 */
export declare const getHtmlStyleId: (style: HtmlStyle) => number;
//# sourceMappingURL=htmlStyleIds.d.ts.map