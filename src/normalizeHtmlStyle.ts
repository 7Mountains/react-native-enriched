import { type ColorValue, processColor } from 'react-native';
import type { HtmlStyleInternal } from './EnrichedTextInputNativeComponent';
import type { HtmlStyle } from './types';

const defaultStyle: Required<HtmlStyle> = {
  h1: {
    fontSize: 32,
    bold: false,
  },
  h2: {
    fontSize: 24,
    bold: false,
  },
  h3: {
    fontSize: 20,
    bold: false,
  },
  h4: {
    fontSize: 16,
    bold: false,
  },
  h5: {
    fontSize: 14,
    bold: false,
  },
  h6: {
    fontSize: 12,
    bold: false,
  },
  blockquote: {
    borderColor: 'darkgray',
    borderWidth: 4,
    gapWidth: 16,
    color: undefined,
  },
  codeblock: {
    color: 'black',
    borderRadius: 8,
    backgroundColor: 'darkgray',
  },
  code: {
    color: 'red',
    backgroundColor: 'darkgray',
  },
  a: {
    color: 'blue',
    textDecorationLine: 'underline',
  },
  mention: {
    color: 'blue',
    backgroundColor: 'yellow',
    textDecorationLine: 'underline',
  },
  content: {
    title: {
      fontSize: 14,
      color: 'black',
    },
    description: {
      fontSize: 10,
      color: 'gray',
    },
    container: {
      borderStyle: 'solid',
      borderRadius: 8,
      marginRight: 0,
      marginLeft: 0,
      paddingRight: 0,
      paddingLeft: 0,
      paddingTop: 8,
      paddingBottom: 8,
      marginTop: 0,
      marginBottom: 0,
    },
    imageContainer: {},
    image: {},
    textContainer: {},
  },
  img: {
    width: 80,
    height: 80,
  },
  ol: {
    gapWidth: 16,
    marginLeft: 16,
    markerFontWeight: undefined,
    markerColor: undefined,
  },
  ul: {
    bulletColor: 'black',
    bulletSize: 8,
    marginLeft: 16,
    gapWidth: 16,
  },
  checkbox: {
    imageWidth: 24,
    imageHeight: 24,
    marginLeft: 8,
    gapWidth: 8,
    checkedTextColor: 'gray',
  },
  divider: {
    height: 20,
    color: 'darkgray',
    thickness: 2,
  },
  mdf: {
    imageUri: '',
    title: {
      fontSize: 14,
      color: 'black',
    },
    container: {
      minHeight: 56,
      borderRadius: 6,
      borderColor: 'gray',
      borderWidth: 1,
      backgroundColor: 'lightgrey',
    },
    image: {
      width: 14,
      height: 16,
    },
    imageContainer: {
      width: 24,
      height: 24,
      borderRadius: 6,
    },
  },
};

const convertToHtmlStyleInternal = (style: HtmlStyle): HtmlStyleInternal => {
  let markerFontWeight: string | undefined;
  if (style.ol?.markerFontWeight) {
    if (typeof style.ol?.markerFontWeight === 'number') {
      markerFontWeight = String(style.ol?.markerFontWeight);
    } else if (typeof style.ol?.markerFontWeight === 'string') {
      markerFontWeight = style.ol?.markerFontWeight;
    }
  }

  const olStyles = {
    ...style.ol,
    markerFontWeight: markerFontWeight,
  };

  return {
    ...style,
    ol: olStyles,
  };
};

const assignDefaultValues = (style: HtmlStyleInternal): HtmlStyleInternal => {
  const merged: Record<string, any> = { ...defaultStyle };

  for (const key in style) {
    if (key === 'mention') {
      merged[key] = {
        ...(style.mention as object),
      };

      continue;
    }

    merged[key] = {
      ...defaultStyle[key as keyof HtmlStyle],
      ...(style[key as keyof HtmlStyle] as object),
    };
  }

  return merged;
};

const parseStyle = (name: string, value: unknown) => {
  if (name !== 'color' && !name.endsWith('Color')) {
    return value;
  }

  return processColor(value as ColorValue);
};

const parseRecursive = (obj: any): any => {
  if (obj == null || typeof obj !== 'object') {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map(parseRecursive);
  }

  const result: Record<string, any> = {};

  for (const [key, value] of Object.entries(obj)) {
    if (value != null && typeof value === 'object') {
      result[key] = parseRecursive(value);
    } else {
      result[key] = parseStyle(key, value);
    }
  }

  return result;
};

export const normalizeHtmlStyle = (style: HtmlStyle): HtmlStyleInternal => {
  const converted = convertToHtmlStyleInternal(style);
  const withDefaults = assignDefaultValues(converted);
  return parseRecursive(withDefaults);
};
