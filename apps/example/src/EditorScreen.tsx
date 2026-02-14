import {
  View,
  StyleSheet,
  Text,
  ScrollView,
  Platform,
  Image,
} from 'react-native';
import {
  EnrichedTextInput,
  type EnrichedTextInputInstance,
  type OnLinkDetected,
  type OnChangeMentionEvent,
  type OnChangeStateEvent,
  type OnChangeSelectionEvent,
  type HtmlStyle,
  type OnChangeColorEvent,
  type Cookie,
} from 'react-native-enriched';
import { useRef, useState } from 'react';
import { Button } from './components/Button';
import { Toolbar } from './components/Toolbar';
import { LinkModal } from './components/LinkModal';
import { ValueModal } from './components/ValueModal';
import { launchImageLibrary } from 'react-native-image-picker';
import { type MentionItem, MentionPopup } from './components/MentionPopup';
import { useUserMention } from './hooks/useUserMention';
import { useChannelMention } from './hooks/useChannelMention';
import { HtmlSection } from './components/HtmlSection';
import { ImageModal } from './components/ImageModal';
import {
  DEFAULT_IMAGE_HEIGHT,
  DEFAULT_IMAGE_WIDTH,
  prepareImageDimensions,
} from './utils/prepareImageDimensions';
import ColorPreview from './components/ColorPreview';
import { Rectangle } from './Rectangle';
import { ContentModal } from './components/ContentModal';

type CurrentLinkState = OnLinkDetected;

interface Selection {
  start: number;
  end: number;
  text: string;
}

const PRIMARY_COLOR = '#000000';

const DEFAULT_STATE = {
  isActive: false,
  canNotBeApplied: false,
  isConflicting: false,
};

const DEFAULT_STYLE: OnChangeStateEvent = {
  alignment: DEFAULT_STATE,
  bold: DEFAULT_STATE,
  italic: DEFAULT_STATE,
  underline: DEFAULT_STATE,
  strikeThrough: DEFAULT_STATE,
  inlineCode: DEFAULT_STATE,
  h1: DEFAULT_STATE,
  h2: DEFAULT_STATE,
  h3: DEFAULT_STATE,
  h4: DEFAULT_STATE,
  h5: DEFAULT_STATE,
  h6: DEFAULT_STATE,
  blockQuote: DEFAULT_STATE,
  codeBlock: DEFAULT_STATE,
  orderedList: DEFAULT_STATE,
  unorderedList: DEFAULT_STATE,
  link: DEFAULT_STATE,
  image: DEFAULT_STATE,
  mention: DEFAULT_STATE,
  checkList: DEFAULT_STATE,
  colored: DEFAULT_STATE,
  content: DEFAULT_STATE,
};

const DEFAULT_LINK_STATE = {
  text: '',
  url: '',
  start: 0,
  end: 0,
};

const DEBUG_SCROLLABLE = false;

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
    parts.push(
      `<h1 alignment="center">Heading ${i + 1}</h1>`,
      `<p><a href="test.com">test link</a> <mention type="channel" indicator="@" text="@test">@test</mention> This is a paragraph with some <b>bold</b>, <i>italic</i>, <u>underline</u>, and <s>strikethrough</s> text. Here's some inline code:</p>`,
      `<h2>Subheading ${i + 1}</h2>`,
      `<h3>Subheading ${i + 1}</h3>`,
      `<h4>Subheading ${i + 1}</h4>`,
      `<h5>Subheading ${i + 1}</h5>`,
      `<h6>Subheading ${i + 1}</h6>`,
      `<p><font color="#ff0000"> This is a colored paragraph.</font></p>`,
      `<ul><li>Ordered list item ${i + 1}.1</li><li>Ordered list item ${i + 1}.2</li></ul>`,
      `<ol><li>Unordered list item ${i + 1}.1</li><li>Unordered list item ${i + 1}.2</li></ol>`,
      `<checklist checked="${i % 2 === 0}">Check list item ${i + 1}</checklist>`,
      `<blockquote>This is a block quote for item ${i + 1}.</blockquote>`,
      `\n<content type="image" src="https://picsum.photos/200/300" text="Test text" />`,
      `\n<content type="placeholder" src="${Image.resolveAssetSource(require('../assets/placeholder.png')).uri}" text="Test text" />`
    );
  }

  parts.push('\n</html>');
  return parts.join('').replaceAll('\n', '');
};

export const cookies: Cookie[] = [
  {
    domain: 'master.saganews.app',
    name: 'CloudFront-Key-Pair-Id',
    value: 'KXHKVUTKYURDE',
  },
  {
    domain: 'master.saganews.app',
    name: 'CloudFront-Signature',
    value:
      'nuRb~TAfjnt59ON0mdBLaLLCeamhU2qdrcwQhiitxx4-8awjLvYw8xhqea0pbPI8c3jIJaPAobw9pNqQEhFXy7iKr6DLqumP3PHKciUvyF47hS-dNvojmlSAA7OeukJ0A8fp04gILqdGnthRcXcEr3VtTjjuH2eFLP8bMQSLBFbe882loTU5aqSoxJb2JKAyRhTpJbGRYCu4fCbDIdP1C0jv56upi5jJARGbMfLYeJ~BBDxgv~Ux7lcwmvlw3tlc3ufHuRs4CS-CT-FoFqBjYAjiKBy9sWg-8ennsuVvtd3vCT2EOo1jAA-8eBMoJimScSDsGugqtA6byZxQngQ45A__',
  },
  {
    domain: 'master.saganews.app',
    name: 'CloudFront-Policy',
    value:
      'eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9tYXN0ZXIuc2FnYW5ld3MuYXBwL2RhdGFzdG9yZS8qIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNzcwMzgzNjgwfX19XX0_',
  },
];

const initialHugeHtml = generateHugeHtml();

export default function EditorScreen() {
  const [isChannelPopupOpen, setIsChannelPopupOpen] = useState(false);
  const [isUserPopupOpen, setIsUserPopupOpen] = useState(false);
  const [isLinkModalOpen, setIsLinkModalOpen] = useState(false);
  const [isImageModalOpen, setIsImageModalOpen] = useState(false);
  const [isValueModalOpen, setIsValueModalOpen] = useState(false);
  const [isContentModalVisible, setIsContentModalVisible] = useState(false);
  const [currentHtml] = useState('');
  const [paragraphAlignment, setParagraphAlignment] =
    useState<string>('default');
  const [requestHtmlTime, setRequestHtmlTime] = useState<number | null>(null);

  const [selection, setSelection] = useState<Selection>();
  const [stylesState, setStylesState] =
    useState<OnChangeStateEvent>(DEFAULT_STYLE);
  const [currentLink, setCurrentLink] =
    useState<CurrentLinkState>(DEFAULT_LINK_STATE);
  const [selectionColor, setSelectionColor] = useState<string>(PRIMARY_COLOR);

  const ref = useRef<EnrichedTextInputInstance>(null);

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
    ref.current?.setMention('@', `@${item.name}`, 'user', {
      id: item.id,
    });
  };

  const handleChannelMentionSelected = (item: MentionItem) => {
    ref.current?.setMention('', `${item.name}`, 'channel', {
      id: item.id,
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

  const handleContentButtonPress = () => {
    setIsContentModalVisible(true);
  };

  const handleContentModalClose = () => {
    setIsContentModalVisible(false);
  };

  const handleContentSubmit = (
    text: string,
    type: string,
    src: string,
    attributes: string
  ) => {
    ref.current?.addContent(text, type, src, attributes);
    handleContentModalClose();
  };

  return (
    <>
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
      >
        <Text style={styles.label}>
          Enriched Text Input {paragraphAlignment}{' '}
          {requestHtmlTime !== null
            ? `- Last HTML request time: ${requestHtmlTime.toFixed(2)} ms`
            : ''}
        </Text>
        <Rectangle />
        <Button
          title="Request html"
          onPress={async () => {
            const start = performance.now();
            console.log('Requesting HTML...');
            const result = await ref.current?.getHTML();
            const end = performance.now();
            console.log('HTML:', result);
            setRequestHtmlTime(end - start);
          }}
        />
        <View style={styles.editor}>
          <EnrichedTextInput
            ref={ref}
            mentionIndicators={['@', '#']}
            style={styles.editorInput}
            htmlStyle={htmlStyle}
            placeholder="Type something here..."
            iOSparagraphSpacing={3}
            iOSparagraphSpacingBefore={3}
            placeholderTextColor="rgb(0, 26, 114)"
            selectionColor="deepskyblue"
            cursorColor="dodgerblue"
            autoCapitalize="sentences"
            // onChangeText={(e) => handleChangeText(e.nativeEvent)}
            // onChangeHtml={(e) => handleChangeHtml(e.nativeEvent)}
            onChangeState={(e) => handleChangeState(e.nativeEvent)}
            defaultValue={initialHugeHtml}
            onColorChangeInSelection={(e) => {
              handleSelectionColorChange(e.nativeEvent);
            }}
            onParagraphAlignmentChange={(e) => {
              setParagraphAlignment(e.nativeEvent.alignment);
              console.log(e.nativeEvent.alignment);
            }}
            onLinkDetected={handleLinkDetected}
            onMentionDetected={console.log}
            onStartMention={handleStartMention}
            onChangeMention={handleChangeMention}
            onEndMention={handleEndMention}
            onFocus={handleFocusEvent}
            onBlur={handleBlurEvent}
            loaderCookies={cookies}
            onChangeSelection={(e) => handleSelectionChangeEvent(e.nativeEvent)}
            androidExperimentalSynchronousEvents={
              ANDROID_EXPERIMENTAL_SYNCHRONOUS_EVENTS
            }
          />
          <Toolbar
            stylesState={stylesState}
            editorRef={ref}
            selectionColor={selectionColor}
            onOpenLinkModal={openLinkModal}
            onSelectImage={openImageModal}
            onContentButtonPress={handleContentButtonPress}
            onMentionPress={() => {
              userMention.onMentionChange('');
              openUserMentionPopup();
            }}
          />
        </View>
        <View style={styles.buttonStack}>
          <Button title="Focus" onPress={handleFocus} style={styles.button} />
          <Button title="Blur" onPress={handleBlur} style={styles.button} />
        </View>
        <Button
          title="Add Divider"
          onPress={() => ref.current?.addDividerAtNewLine()}
          style={styles.valueButton}
        />
        <Button
          title="Set input's value"
          onPress={openValueModal}
          style={styles.valueButton}
        />
        <Button
          title="toggle check list"
          onPress={() => ref.current?.toggleCheckList()}
        />
        <Button
          title="remove color"
          onPress={() => ref.current?.removeColor()}
        />
        <Button
          title="set right alignment"
          onPress={() => ref.current?.setParagraphAlignment('right')}
        />
        <Button
          title="set left alignment"
          onPress={() => ref.current?.setParagraphAlignment('left')}
        />
        <Button
          title="set center alignment"
          onPress={() => ref.current?.setParagraphAlignment('center')}
        />
        <Button
          title="set default alignment"
          onPress={() => ref.current?.setParagraphAlignment('default')}
        />
        <Text>is Check list {stylesState.checkList.isActive}</Text>
        <HtmlSection currentHtml={currentHtml} />
        {DEBUG_SCROLLABLE && <View style={styles.scrollPlaceholder} />}
        <ColorPreview color={selectionColor} />
      </ScrollView>
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
      <ContentModal
        visible={isContentModalVisible}
        onClose={handleContentModalClose}
        onSubmit={handleContentSubmit}
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
      textColor: 'black',
      backgroundColor: 'lightgray',
      borderRadius: 4,
      marginTop: 4,
      marginBottom: 4,
      paddingLeft: 0,
      paddingRight: 0,
      imageBorderRadiusTopLeft: 4,
      imageBorderRadiusBottomLeft: 4,
      imageResizeMode: 'stretch',
      imageWidth: 50,
      height: 50,
      imageHeight: 50,
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
      height: 50,
      imageBorderRadiusTopLeft: 4,
      imageBorderRadiusBottomLeft: 4,
      imageResizeMode: 'stretch',
      imageWidth: 50,
      imageHeight: 50,
      fallbackImageURI: Image.resolveAssetSource(
        require('../assets/placeholder.png')
      ).uri,
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
    marginTop: 24,
    width: '100%',
    maxHeight: 300,
    backgroundColor: 'gainsboro',
    fontSize: 16,
    fontFamily: 'Nunito-Regular',
    paddingVertical: 12,
    paddingHorizontal: 14,
    color: 'black',
  },
  scrollPlaceholder: {
    marginTop: 24,
    width: '100%',
    height: 1000,
    backgroundColor: 'rgb(0, 26, 114)',
  },
});
