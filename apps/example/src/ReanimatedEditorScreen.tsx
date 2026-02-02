import { StyleSheet, Image, View } from 'react-native';
import {
  type EnrichedTextInputInstance,
  type HtmlStyle,
  type OnChangeStateEvent,
  EnrichedReanimatedTextInput,
  useReanimatedScrollOffset,
} from 'react-native-enriched';
import { useCallback, useState } from 'react';
import {
  useAnimatedProps,
  useAnimatedRef,
  useSharedValue,
  interpolate,
  scrollTo,
} from 'react-native-reanimated';
import {
  useFocusedInputHandler,
  useKeyboardHandler,
  useReanimatedFocusedInput,
  useWindowDimensions,
} from 'react-native-keyboard-controller';
import { Toolbar } from './components/Toolbar';

const generateHugeHtml = (repeat = 2) => {
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

const bottomOffset = 0;

type SelectionPosition = {
  x: number;
  y: number;
  position: number;
};

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

export default function EditorScreen() {
  const keyboardHeight = useSharedValue(0);
  const currentSelectionPosition = useSharedValue<SelectionPosition>({
    x: 0,
    y: 0,
    position: 0,
  });
  const scrollOffsetBeforeKeyboard = useSharedValue(0);
  const nextKeyboardHeight = useSharedValue(0);

  const [toolbarState, setToolbarState] = useState(DEFAULT_STYLE);

  const ref = useAnimatedRef<EnrichedTextInputInstance>();

  const { height } = useWindowDimensions();

  const { input } = useReanimatedFocusedInput();

  const { scrollHandler, scrollOffset } = useReanimatedScrollOffset();

  useFocusedInputHandler(
    {
      onSelectionChange: (e) => {
        'worklet';
        currentSelectionPosition.set(e.selection.end);
      },
    },
    [currentSelectionPosition]
  );

  const maybeScroll = useCallback(
    (keyboardHeightEvent: number) => {
      'worklet';
      const inputLayout = input?.get()?.layout;
      if (!inputLayout) return;

      const cursor = currentSelectionPosition.get();
      const absoluteCaretY =
        inputLayout.absoluteY + (cursor.y - scrollOffsetBeforeKeyboard.get());

      const finalScrollDistance =
        scrollOffsetBeforeKeyboard.get() +
        (absoluteCaretY - (height - nextKeyboardHeight.get()) + bottomOffset);

      if (finalScrollDistance >= scrollOffsetBeforeKeyboard.get()) {
        const targetScrollY = interpolate(
          keyboardHeightEvent,
          [0, nextKeyboardHeight.get()],
          [scrollOffsetBeforeKeyboard.get(), finalScrollDistance]
        );

        scrollTo(ref, 0, targetScrollY, false);
      }
    },
    [
      input,
      currentSelectionPosition,
      scrollOffsetBeforeKeyboard,
      height,
      nextKeyboardHeight,
      ref,
    ]
  );

  useKeyboardHandler(
    {
      onStart: (e) => {
        'worklet';
        scrollOffsetBeforeKeyboard.set(scrollOffset.get());
        nextKeyboardHeight.set(e.height);
      },
      onMove: (event) => {
        'worklet';
        keyboardHeight.set(event.height);
        if (nextKeyboardHeight.get() > 0) {
          maybeScroll(event.height);
        }
      },
    },
    [maybeScroll, nextKeyboardHeight, scrollOffset, scrollOffsetBeforeKeyboard]
  );

  const animatedProps = useAnimatedProps(
    () => ({
      contentInsets: {
        bottom:
          nextKeyboardHeight.get() === 0
            ? keyboardHeight.get()
            : nextKeyboardHeight.get() + bottomOffset,
        top: 0,
        left: 0,
        right: 0,
      },
      scrollIndicatorInsets: {
        bottom:
          nextKeyboardHeight.get() === 0
            ? keyboardHeight.get()
            : nextKeyboardHeight.get() + bottomOffset,
        top: 0,
        left: 0,
        right: 0,
      },
    }),
    [keyboardHeight, bottomOffset, nextKeyboardHeight]
  );

  return (
    <>
      <View>
        <Toolbar
          editorRef={ref}
          stylesState={toolbarState}
          onOpenLinkModal={() => {}}
          onSelectImage={() => {}}
          selectionColor={null}
        />
      </View>
      <EnrichedReanimatedTextInput
        ref={ref}
        animatedProps={animatedProps}
        mentionIndicators={['@', '#']}
        style={styles.editorInput}
        htmlStyle={htmlStyle}
        onChangeState={(e) => {
          setToolbarState(e.nativeEvent);
        }}
        automaticallyAdjustsScrollIndicatorInsets={false}
        onScroll={scrollHandler}
        defaultValue={initialHugeHtml}
        placeholder="Type something here..."
        placeholderTextColor="rgb(0, 26, 114)"
        selectionColor="deepskyblue"
        cursorColor="dodgerblue"
        autoCapitalize="sentences"
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
