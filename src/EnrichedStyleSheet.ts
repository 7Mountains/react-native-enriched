import { getHtmlStyleId } from './htmlStyleIds';
import { normalizeHtmlStyle } from './normalizeHtmlStyle';
import type { HtmlStyle } from './types';

/**
 * Freezes the plain objects of the value, its colors (e.g. `PlatformColor`)
 * left as they are
 *
 * @param value - The value
 */
const freezePlainObjects = (value: unknown) => {
  if (
    value === null ||
    typeof value !== 'object' ||
    Object.getPrototypeOf(value) !== Object.prototype ||
    Object.isFrozen(value)
  ) {
    return;
  }

  Object.freeze(value);
  Object.values(value).forEach(freezePlainObjects);
};

/**
 * The styles of the enriched components made once, outside of the render, as
 * React Native's `StyleSheet`
 */
export const EnrichedStyleSheet = {
  /**
   * An html style ready for the enriched components as it's made:
   * `EnrichedText` takes it by its registered id and `EnrichedTextInput` by
   * its normalized form, neither converts it while rendering. Frozen: changed
   * after, its registered id wouldn't follow it.
   *
   * @param style - The html style
   * @returns The same style, frozen
   */
  createHtmlStyle<T extends HtmlStyle>(style: T): Readonly<T> {
    getHtmlStyleId(style);
    normalizeHtmlStyle(style);
    freezePlainObjects(style);

    return style;
  },
};
