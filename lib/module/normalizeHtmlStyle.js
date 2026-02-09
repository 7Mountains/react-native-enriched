"use strict";

import { Image, processColor } from 'react-native';
const defaultStyle = {
  h1: {
    fontSize: 32,
    bold: false
  },
  h2: {
    fontSize: 24,
    bold: false
  },
  h3: {
    fontSize: 20,
    bold: false
  },
  h4: {
    fontSize: 16,
    bold: false
  },
  h5: {
    fontSize: 14,
    bold: false
  },
  h6: {
    fontSize: 12,
    bold: false
  },
  blockquote: {
    borderColor: 'darkgray',
    borderWidth: 4,
    gapWidth: 16,
    color: undefined
  },
  codeblock: {
    color: 'black',
    borderRadius: 8,
    backgroundColor: 'darkgray'
  },
  code: {
    color: 'red',
    backgroundColor: 'darkgray'
  },
  a: {
    color: 'blue',
    textDecorationLine: 'underline'
  },
  mention: {
    color: 'blue',
    backgroundColor: 'yellow',
    textDecorationLine: 'underline'
  },
  content: {
    backgroundColor: 'transparent',
    textColor: 'black',
    borderColor: 'darkgray',
    borderRadius: 8,
    borderStyle: 'solid',
    borderWidth: 1,
    marginRight: 0,
    marginLeft: 0,
    paddingRight: 0,
    paddingLeft: 0,
    paddingTop: 8,
    paddingBottom: 8,
    marginTop: 0,
    marginBottom: 0,
    imageBorderRadiusBottomLeft: 0,
    imageBorderRadiusBottomRight: 0,
    imageBorderRadiusTopLeft: 0,
    imageBorderRadiusTopRight: 0,
    imageHeight: 0,
    imageWidth: 0,
    imageResizeMode: 'stretch',
    fontSize: 14
  },
  img: {
    width: 80,
    height: 80
  },
  ol: {
    gapWidth: 16,
    marginLeft: 16,
    markerFontWeight: undefined,
    markerColor: undefined
  },
  ul: {
    bulletColor: 'black',
    bulletSize: 8,
    marginLeft: 16,
    gapWidth: 16
  },
  checkbox: {
    imageWidth: 24,
    imageHeight: 24,
    checkedImage: undefined,
    uncheckedImage: undefined,
    marginLeft: 8,
    gapWidth: 8,
    checkedTextColor: 'gray'
  },
  divider: {
    height: 20,
    color: 'darkgray',
    thickness: 2
  }
};
const convertToHtmlStyleInternal = style => {
  let markerFontWeight;
  if (style.ol?.markerFontWeight) {
    if (typeof style.ol?.markerFontWeight === 'number') {
      markerFontWeight = String(style.ol?.markerFontWeight);
    } else if (typeof style.ol?.markerFontWeight === 'string') {
      markerFontWeight = style.ol?.markerFontWeight;
    }
  }
  const olStyles = {
    ...style.ol,
    markerFontWeight: markerFontWeight
  };
  const checkboxStyles = {
    ...style.checkbox,
    checkedImage: style.checkbox?.checkedImage ? Image.resolveAssetSource(style.checkbox.checkedImage).uri : undefined,
    uncheckedImage: style.checkbox?.uncheckedImage ? Image.resolveAssetSource(style.checkbox.uncheckedImage).uri : undefined
  };
  return {
    ...style,
    ol: olStyles,
    checkbox: checkboxStyles
  };
};
const assignDefaultValues = style => {
  const merged = {
    ...defaultStyle
  };
  for (const key in style) {
    if (key === 'mention') {
      merged[key] = {
        ...style.mention
      };
      continue;
    }
    merged[key] = {
      ...defaultStyle[key],
      ...style[key]
    };
  }
  return merged;
};
const parseStyle = (name, value) => {
  if (name !== 'color' && !name.endsWith('Color')) {
    return value;
  }
  return processColor(value);
};
const parseColors = style => {
  const finalStyle = {};
  for (const [tagName, tagStyle] of Object.entries(style)) {
    const tagStyles = {};
    if (tagName === 'mention') {
      for (const [type, mentionStyle] of Object.entries(tagStyle)) {
        tagStyles[type] = {};
        for (const [styleName, styleValue] of Object.entries(mentionStyle)) {
          tagStyles[type][styleName] = parseStyle(styleName, styleValue);
        }
      }
      finalStyle[tagName] = tagStyles;
      continue;
    }
    if (tagName === 'content') {
      for (const [type, contentStyle] of Object.entries(tagStyle)) {
        tagStyles[type] = {};
        for (const [styleName, styleValue] of Object.entries(contentStyle)) {
          tagStyles[type][styleName] = parseStyle(styleName, styleValue);
        }
      }
      finalStyle[tagName] = tagStyles;
      continue;
    }
    for (const [styleName, styleValue] of Object.entries(tagStyle)) {
      tagStyles[styleName] = parseStyle(styleName, styleValue);
    }
    finalStyle[tagName] = tagStyles;
  }
  return finalStyle;
};
export const normalizeHtmlStyle = style => {
  const converted = convertToHtmlStyleInternal(style);
  const withDefaults = assignDefaultValues(converted);
  return parseColors(withDefaults);
};
//# sourceMappingURL=normalizeHtmlStyle.js.map