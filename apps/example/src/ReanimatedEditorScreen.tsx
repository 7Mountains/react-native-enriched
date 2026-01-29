import {
  View,
  StyleSheet,
  Text,
  ScrollView,
  Platform,
  Image,
} from 'react-native';
import {
  type EnrichedTextInputInstance,
  type OnLinkDetected,
  type OnChangeMentionEvent,
  type OnChangeStateEvent,
  type OnChangeSelectionEvent,
  type HtmlStyle,
  type OnChangeColorEvent,
  EnrichedReanimatedTextInput,
} from 'react-native-enriched';
import { useEffect, useState } from 'react';
import { LinkModal } from './components/LinkModal';
import { ValueModal } from './components/ValueModal';
import { launchImageLibrary } from 'react-native-image-picker';
import { type MentionItem, MentionPopup } from './components/MentionPopup';
import { useUserMention } from './hooks/useUserMention';
import { useChannelMention } from './hooks/useChannelMention';
import { ImageModal } from './components/ImageModal';
import {
  DEFAULT_IMAGE_HEIGHT,
  DEFAULT_IMAGE_WIDTH,
  prepareImageDimensions,
} from './utils/prepareImageDimensions';
import {
  useAnimatedProps,
  useAnimatedRef,
  useSharedValue,
  dispatchCommand,
} from 'react-native-reanimated';
import { useKeyboardHandler } from 'react-native-keyboard-controller';
import { runOnUI } from 'react-native-worklets';

type CurrentLinkState = OnLinkDetected;

interface Selection {
  start: number;
  end: number;
  text: string;
}

const PRIMARY_COLOR = '#000000';

const DEFAULT_STYLE: OnChangeStateEvent = {
  bold: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  italic: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  underline: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  strikeThrough: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  inlineCode: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  h1: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  h2: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  h3: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  h4: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  h5: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  h6: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  blockQuote: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  codeBlock: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  orderedList: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  unorderedList: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  link: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  image: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  mention: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  checkList: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  colored: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
  content: {
    isActive: false,
    canBeApplied: false,
    isConflicting: false,
  },
};

const DEFAULT_LINK_STATE = {
  text: '',
  url: '',
  start: 0,
  end: 0,
};

// Enabling this prop fixes input flickering while auto growing.
// However, it's still experimental and not tested well.
// Disabled for now, as it's causing some strange issues.
// See: https://github.com/software-mansion/react-native-enriched/issues/229
const ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS = false;

const generateHugeHtml = (repeat = 10) => {
  const parts: string[] = [];
  parts.push('<html>');

  // small helper to make deterministic colors
  // const colorAt = (i: number) => {
  //   const r = (37 * (i + 1)) % 256;
  //   const g = (83 * (i + 7)) % 256;
  //   const b = (199 * (i + 13)) % 256;
  //   const toHex = (n: number) => n.toString(16).padStart(2, '0');
  //   return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
  // };

  for (let i = 0; i < repeat; i++) {
    // const col = colorAt(i);
    const imgW = 200 + (i % 5) * 40;
    const imgH = 100 + (i % 3) * 30;

    parts.push(
      // Headings
      `\n<h1>Section ${i + 1}</h1>`,
      `\n<h2 alignment="center">Subsection ${i + 1}.1</h2>`,
      `\n<h3>Topic ${i + 1}.1.a</h3>`, // Paragraph with mixed inline styles
      `\n<p>This is a <b>bold</b> and <i>italic</i> paragraph with <u>underline</u>, ` +
        `<s>strike</s>, <code>inline_code_${i}</code>, ` +
        `<a href="https://example.com/${i}">a link ${i}</a>, ` +
        `<mention text="@alex_${i}" indicator="@">@alex_${i}</mention>, ` +
        `<mention text="#general" indicator="#" text="#general">#general</mention>, ` +
        `and some plain text to bulk it up.</p>`,

      // Line break
      `\n<hr>`,

      // Unordered list
      `<ul>`,
      `<li>bullet A ${i}</li>`,
      `<li>bullet B ${i}</li>`,
      `<li>bullet C ${i}</li>`,
      `</ul>`,

      // Ordered list
      `\n<ol>`,
      `\n<li>step 1.${i}</li>`,
      `\n<li>step 2.${i}</li>`,
      `\n<li>step 3.${i}</li>`,
      `\n</ol>`,

      // Blockquote
      `\n<blockquote>"Blockquote line 1 for ${i}."</blockquote>`,
      `\n<blockquote>"Blockquote line 2 for ${i}."</blockquote>`,

      // Code block (escaped characters)
      `\n<codeblock>`,
      `\n<p>for (let k = 0; k < ${i % 7}; k++) { console.log(&quot;block_${i}&quot;); }</p>`,
      `\n</codeblock>`,
      `\n<content type="image" text="Test text" src="https://picsum.photos/seed/${i}/${imgW}/${imgH}" width="${Math.min(imgW, 300)}" height="${imgH}" />`
    );
  }

  parts.push('\n</html>');
  return parts.join('').replaceAll('\n', '');
};

const initialHugeHtml = generateHugeHtml();

export default function ReanimatedEditorScreen() {
  const [isChannelPopupOpen, setIsChannelPopupOpen] = useState(false);
  const [isUserPopupOpen, setIsUserPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [isImageModalOpen, setIsImageModalOpen] = useState(false);
  const [isValueModalOpen, setIsValueModalOpen] = useState(false);
  const keyboardHeight = useSharedValue(0);

  useKeyboardHandler({
    onMove: (event) => {
      'worklet';
      keyboardHeight.set(event.height);
    },
  });

  const [selection, setSelection] = useState<Selection>();
  const [stylesState, setStylesState] =
    useState<OnChangeStateEvent>(DEFAULT_STYLE);
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);

  const ref = useAnimatedRef<EnrichedTextInputInstance>();

  const userMention = useUserMention();
  const channelMention = useChannelMention();

  const insideCurrentLink =
    stylesState.link.isActive &&
    currentLink.url.length > 0 &&
    (currentLink.start || currentLink.end) &&
    selection &&
    selection.start >= currentLink.start &&
    selection.end <= currentLink.end;

  const handleChangeState = (state: OnChangeStateEvent) => {
    setStylesState(state);
  };

  const handleFocus = () => {
    ref.current?.focus();
  };

  const handleBlur = () => {
    ref.current?.blur();
  };

  const openLinkModal = () => {
    setIsLinkModalOpen(true);
  };

  const closeLinkModal = () => {
    setIsLinkModalOpen(false);
  };

  const openImageModal = () => {
    setIsImageModalOpen(true);
  };

  const closeImageModal = () => {
    setIsImageModalOpen(false);
  };

  const openUserMentionPopup = () => {
    setIsUserPopupOpen(true);
  };

  const closeUserMentionPopup = () => {
    setIsUserPopupOpen(false);
    userMention.onMentionChange('');
  };

  const openChannelMentionPopup = () => {
    setIsChannelPopupOpen(true);
  };

  const closeChannelMentionPopup = () => {
    setIsChannelPopupOpen(false);
    channelMention.onMentionChange('');
  };

  const openValueModal = () => {
    setIsValueModalOpen(true);
  };

  const closeValueModal = () => {
    setIsValueModalOpen(false);
  };

  const handleStartMention = (indicator: string) => {
    if (indicator === '@') {
      userMention.onMentionChange('');
      openUserMentionPopup();
      return;
    }

    channelMention.onMentionChange('');
    openChannelMentionPopup();
  };

  const handleEndMention = (indicator: string) => {
    const isUserMention = indicator === '@';

    if (isUserMention) {
      closeUserMentionPopup();
      userMention.onMentionChange('');
      return;
    }

    closeChannelMentionPopup();
    channelMention.onMentionChange('');
  };

  const submitLink = (text: string, url: string) => {
    if (!selection || url.length === 0) {
      closeLinkModal();
      return;
    }

    const newText = text.length > 0 ? text : url;

    if (insideCurrentLink) {
      ref.current?.setLink(currentLink.start, currentLink.end, newText, url);
    } else {
      ref.current?.setLink(selection.start, selection.end, newText, url);
    }

    closeLinkModal();
  };

  const submitSetValue = (value: string) => {
    ref.current?.setValue(value);
    closeValueModal();
  };

  const selectImage = async (
    width: number | undefined,
    height: number | undefined,
    remoteUrl?: string
  ) => {
    if (remoteUrl) {
      ref.current?.setImage(
        remoteUrl,
        width ?? DEFAULT_IMAGE_WIDTH,
        height ?? DEFAULT_IMAGE_HEIGHT
      );
      return;
    }

    const response = await launchImageLibrary({
      mediaType: 'photo',
      selectionLimit: 1,
    });

    if (response?.assets?.[0] === undefined) {
      return;
    }

    const asset = response.assets[0];
    const imageUri = Platform.OS === 'android' ? asset.originalPath : asset.uri;

    if (imageUri) {
      const { finalWidth, finalHeight } = prepareImageDimensions(
        asset,
        width,
        height
      );
      ref.current?.setImage(imageUri, finalWidth, finalHeight);
    }
  };

  const handleChangeMention = ({ indicator, text }: OnChangeMentionEvent) => {
    indicator === '@'
      ? userMention.onMentionChange(text)
      : channelMention.onMentionChange(text);
    indicator === '@'
      ? !isUserPopupOpen && setIsUserPopupOpen(true)
      : !isChannelPopupOpen && setIsChannelPopupOpen(true);
  };

  const handleUserMentionSelected = (item: MentionItem) => {
    ref.current?.setMention('@', `@${item.name}`, {
      id: item.id,
      type: 'user',
    });
  };

  const handleChannelMentionSelected = (item: MentionItem) => {
    ref.current?.setMention('#', `#${item.name}`, {
      id: item.id,
      type: 'channel',
    });
  };

  const handleFocusEvent = () => {
    console.log('Input focused');
  };

  const handleBlurEvent = () => {
    console.log('Input blurred');
  };

  const handleLinkDetected = (state: CurrentLinkState) => {
    console.log(state);
    setCurrentLink(state);
  };

  const handleSelectionChangeEvent = (sel: OnChangeSelectionEvent) => {
    setSelection(sel);
  };

  const handleSelectionColorChange = (e: OnChangeColorEvent) => {
    if (e.color) {
      setSelectionColor(e.color);
    }
  };

  const animatedProps = useAnimatedProps(
    () => ({
      contentInsets: {
        bottom: keyboardHeight.get(),
        top: 0,
        left: 0,
        right: 0,
      },
      scrollIndicatorInsets: {
        bottom: keyboardHeight.get(),
        top: 0,
        left: 0,
        right: 0,
      },
    }),
    [keyboardHeight]
  );

  return (
    <>
      <EnrichedReanimatedTextInput
        ref={ref}
        animatedProps={animatedProps}
        mentionIndicators={['@', '#']}
        style={styles.editorInput}
        htmlStyle={htmlStyle}
        placeholder="Type something here..."
        placeholderTextColor="rgb(0, 26, 114)"
        selectionColor="deepskyblue"
        cursorColor="dodgerblue"
        autoCapitalize="sentences"
        // onChangeText={(e) => handleChangeText(e.nativeEvent)}
        // onChangeHtml={(e) => handleChangeHtml(e.nativeEvent)}
        onChangeState={(e) => handleChangeState(e.nativeEvent)}
        defaultValue={initialHugeHtml}
        onLayout={(e) => {
          console.log(e.nativeEvent.layout);
        }}
        onColorChangeInSelection={(e) => {
          handleSelectionColorChange(e.nativeEvent);
        }}
        onParagraphAlignmentChange={(e) => {
          console.log(e.nativeEvent.alignment);
        }}
        onLinkDetected={handleLinkDetected}
        onMentionDetected={console.log}
        onStartMention={handleStartMention}
        onChangeMention={handleChangeMention}
        onEndMention={handleEndMention}
        onFocus={handleFocusEvent}
        onBlur={handleBlurEvent}
        onChangeSelection={(e) => handleSelectionChangeEvent(e.nativeEvent)}
        androidExperimentalSynchronousEvents={
          ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS
        }
      />
      <LinkModal
        isOpen={isLinkModalOpen}
        editedText={
          insideCurrentLink ? currentLink.text : (selection?.text ?? '')
        }
        editedUrl={insideCurrentLink ? currentLink.url : ''}
        onSubmit={submitLink}
        onClose={closeLinkModal}
      />
      <ImageModal
        isOpen={isImageModalOpen}
        onSubmit={selectImage}
        onClose={closeImageModal}
      />
      <ValueModal
        isOpen={isValueModalOpen}
        onSubmit={submitSetValue}
        onClose={closeValueModal}
      />
      <MentionPopup
        variant="user"
        data={userMention.data}
        isOpen={isUserPopupOpen}
        onItemPress={handleUserMentionSelected}
      />
      <MentionPopup
        variant="channel"
        data={channelMention.data}
        isOpen={isChannelPopupOpen}
        onItemPress={handleChannelMentionSelected}
      />
    </>
  );
}

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
    '#': {
      color: 'blue',
      backgroundColor: 'lightblue',
      textDecorationLine: 'none',
    },
    '@': {
      color: 'green',
      backgroundColor: 'lightgreen',
      textDecorationLine: 'none',
    },
  },
  content: {
    image: {
      textColor: 'black',
      backgroundColor: 'lightgray',
      borderRadius: 4,
      paddingTop: 20,
      paddingBottom: 20,
      marginTop: 4,
      marginBottom: 4,
      paddingLeft: 0,
      paddingRight: 0,
      imageBorderRadiusTopLeft: 4,
      imageBorderRadiusBottomLeft: 4,
      imageResizeMode: 'stretch',
      imageWidth: 50,
      imageHeight: 56,
      fontSize: 14,
      fontWeight: '900',
      fallbackImageURI: Image.resolveAssetSource(
        require('../assets/placeholder.png')
      ).uri,
    },
    video: {
      borderWidth: 1,
      borderColor: 'blue',
      textColor: 'blue',
      borderStyle: 'dotted',
      borderRadius: 4,
      paddingTop: 16,
      paddingBottom: 16,
      marginTop: 4,
      marginBottom: 4,
    },
    placeholder: {
      borderWidth: 1,
      borderColor: 'blue',
      textColor: 'blue',
      borderStyle: 'dotted',
      borderRadius: 4,
      paddingTop: 14,
      paddingBottom: 14,
      marginTop: 8,
      marginBottom: 8,
      imageWidth: 50,
      imageBorderRadiusTopLeft: 4,
      imageBorderRadiusBottomLeft: 4,
      imageResizeMode: 'cover',
    },
    test: {
      borderColor: 'red',
      borderWidth: 1,
      paddingTop: 10,
      paddingBottom: 10,
      borderRadius: 8,
      borderStyle: 'dashed',
      textColor: 'blue',
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
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white',
  },
  content: {
    flexGrow: 1,
    padding: 16,
    paddingTop: 100,
    alignItems: 'center',
  },
  editor: {
    width: '100%',
  },
  label: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    color: 'rgb(0, 26, 114)',
  },
  buttonStack: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    width: '100%',
  },
  button: {
    width: '45%',
  },
  valueButton: {
    width: '100%',
  },
  editorInput: {
    width: '100%',
    flex: 1,
    backgroundColor: 'gainsboro',
    fontSize: 18,
    fontFamily: 'Nunito-Regular',
    paddingVertical: 12,
    paddingHorizontal: 14,
    paddingBottom: 0,
    color: 'black',
  },
  scrollPlaceholder: {
    marginTop: 24,
    width: '100%',
    height: 1000,
    backgroundColor: 'rgb(0, 26, 114)',
  },
});
