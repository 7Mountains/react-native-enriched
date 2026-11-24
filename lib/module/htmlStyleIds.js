"use strict";

import NativeEnrichedHtmlStyles from './NativeEnrichedHtmlStyles';
import { normalizeHtmlStyle } from "./normalizeHtmlStyle.js";
const idsByStyle = new WeakMap();
// A style created again with the same values (e.g. inline) isn't normalized
// or registered again
const idsBySource = new Map();
const idsByContent = new Map();

/**
 * The values JSON leaves out or merges, kept apart: an undefined value
 * replaces its default, and the numbers that aren't finite all become null
 *
 * @param _key - The key of the value
 * @param value - The value
 * @returns The value to serialize
 */
const keepDistinctValues = (_key, value) => {
  if (value === undefined) {
    return '\u0000undefined';
  }
  if (typeof value === 'number' && !Number.isFinite(value)) {
    return `\u0000${value}`;
  }
  return value;
};

/**
 * The id of the html style registered natively: the texts pass the id instead
 * of the style, which isn't converted and copied for every text.
 *
 * @param style - The html style
 * @returns The id of the style, 0 without the native module
 */
export const getHtmlStyleId = style => {
  const cachedId = idsByStyle.get(style);
  if (cachedId !== undefined) {
    return cachedId;
  }
  if (!NativeEnrichedHtmlStyles) {
    return 0;
  }
  const source = JSON.stringify(style, keepDistinctValues);
  let id = idsBySource.get(source);
  if (id === undefined) {
    const normalized = normalizeHtmlStyle(style);
    const content = JSON.stringify(normalized);
    id = idsByContent.get(content);
    if (id === undefined) {
      id = NativeEnrichedHtmlStyles.registerHtmlStyle(normalized);
      idsByContent.set(content, id);
    }
    idsBySource.set(source, id);
  }
  idsByStyle.set(style, id);
  return id;
};
//# sourceMappingURL=htmlStyleIds.js.map