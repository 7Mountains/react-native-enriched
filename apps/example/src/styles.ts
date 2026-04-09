import type { HtmlStyle } from 'react-native-enriched';
import { Image } from 'react-native';

const htmlStyle: HtmlStyle = {
  h1: {
    fontSize: 72,
    bold: false,
  },
  h2: {
    fontSize: 60,
    bold: false,
  },
  h3: {
    fontSize: 50,
    bold: false,
  },
  h4: {
    fontSize: 40,
    bold: false,
  },
  h5: {
    fontSize: 30,
    bold: false,
  },
  h6: {
    fontSize: 24,
    bold: false,
  },
  blockquote: {
    borderColor: 'navy',
    borderWidth: 4,
    gapWidth: 4,
    color: 'black',
  },
  codeblock: {
    color: 'black',
    borderRadius: 8,
    backgroundColor: 'aquamarine',
  },
  code: {
    color: 'black',
    backgroundColor: 'yellow',
  },
  a: {
    color: 'blue',
    textDecorationLine: 'underline',
  },
  mention: {
    channel: {
      color: 'blue',
      backgroundColor: 'lightblue',
      textDecorationLine: 'none',
    },
    user: {
      color: 'green',
      backgroundColor: 'lightgreen',
      textDecorationLine: 'none',
    },
  },
  content: {
    image: {
      container: {
        minHeight: 56,
        borderRadius: 4,
        backgroundColor: 'lightgrey',
        marginTop: 4,
        marginBottom: 4,
        paddingRight: 8,
        borderWidth: 2,
        borderColor: 'lightblue',
        borderStyle: 'dashed',
      },
      title: {
        color: 'black',
        fontSize: 14,
        fontWeight: '400',
      },
      subtitle: {
        color: 'black',
        fontSize: 14,
        fontWeight: '400',
      },
      subDescription: {
        color: '#6B7280',
        fontSize: 12,
        fontWeight: '500',
      },
      textContainer: {
        paddingBottom: 4,
        paddingTop: 4,
        marginLeft: 8,
      },
      imageContainer: {
        width: 56,
        height: 56,
      },
      image: {
        width: 56,
      },
      description: {
        color: '#6B7280',
        fontSize: 12,
        fontWeight: '500',
      },
      fallbackImageURI: Image.resolveAssetSource(
        require('../assets/placeholder.png')
      ).uri,
    },
    video: {
      container: {
        minHeight: 56,
        borderRadius: 4,
        backgroundColor: 'transparent',
        marginTop: 4,
        marginBottom: 4,
        paddingRight: 8,
        borderWidth: 1,
        borderColor: 'blue',
      },
      textContainer: {
        paddingLeft: 10,
      },
      title: {
        color: 'black',
        fontSize: 14,
        fontWeight: '400',
      },
      imageContainer: {
        width: 56,
      },
      image: {
        width: 56,
      },
      description: {
        color: '#6B7280',
        fontSize: 12,
        fontWeight: '500',
      },
      fallbackImageURI: Image.resolveAssetSource(
        require('../assets/placeholder.png')
      ).uri,
    },
    placeholder: {
      container: {
        minHeight: 44,
        borderRadius: 4,
        backgroundColor: 'lightgrey',
        marginTop: 4,
        marginBottom: 4,
        paddingRight: 8,
        borderWidth: 1,
      },
      title: {
        color: 'black',
        fontSize: 14,
        fontWeight: '400',
      },
      imageContainer: {
        width: 44,
        height: 44,
      },
      image: {
        width: 44,
        height: 44,
      },
      description: {
        color: '#6B7280',
        fontSize: 12,
        fontWeight: '500',
      },
      fallbackImageURI: Image.resolveAssetSource(
        require('../assets/placeholder.png')
      ).uri,
    },
    automation: {
      container: {
        minHeight: 48,
        borderRadius: 4,
        backgroundColor: 'lightgrey',
        marginTop: 4,
        marginBottom: 4,
        paddingRight: 8,
        borderWidth: 1,
      },
      title: {
        color: 'black',
        fontSize: 14,
        fontWeight: '400',
      },
      textContainer: {
        marginLeft: 8,
      },
      imageContainer: {
        width: 24,
      },
      image: {
        width: 24,
      },
      description: {
        color: '#6B7280',
        fontSize: 12,
        fontWeight: '500',
      },
    },
  },
  img: {
    width: 50,
    height: 50,
  },
  ol: {
    gapWidth: 16,
    marginLeft: 24,
    markerColor: 'navy',
    markerFontWeight: 'bold',
  },
  ul: {
    bulletColor: 'aquamarine',
    bulletSize: 8,
    marginLeft: 24,
    gapWidth: 16,
  },
  checkbox: {
    imageWidth: 24,
    imageHeight: 24,
    checkedImage: require('../assets/images/checkbox_checked.png'),
    uncheckedImage: require('../assets/images/checkbox.png'),
    marginLeft: 0,
    gapWidth: 6,
    checkedTextColor: 'gray',
  },
  divider: {
    height: 24,
    color: 'gray',
    thickness: 2,
  },
  mdf: {
    container: {
      minHeight: 48,
      borderRadius: 8,
      borderWidth: 1,
      borderLeftWidth: 4,
      paddingLeft: 8,
      paddingRight: 8,
      borderColor: 'lightblue',
      backgroundColor: 'lightgrey',
    },
    title: {
      fontSize: 14,
      fontWeight: '600',
    },
    imageContainer: {
      width: 24,
      height: 24,
      borderRadius: 6,
    },
    textContainer: {
      marginLeft: 8,
    },
    image: {
      width: 16,
      height: 18,
    },
    imageUri: Image.resolveAssetSource(
      require('../assets/images/block_icon.png')
    ).uri,
  },
};

export default htmlStyle;
