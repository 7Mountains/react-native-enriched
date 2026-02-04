import { FlatList, type ListRenderItemInfo, StyleSheet } from 'react-native';
import { ToolbarButton } from './ToolbarButton';
import type {
  OnChangeStateEvent,
  EnrichedTextInputInstance,
} from 'react-native-enriched';
import type { FC } from 'react';
import { ToolbarColorButton } from './ToolbarColorButton';

const STYLE_ITEMS = [
  {
    name: 'bold',
    icon: 'bold',
  },
  {
    name: 'italic',
    icon: 'italic',
  },
  {
    name: 'underline',
    icon: 'underline',
  },
  {
    name: 'strikethrough',
    icon: 'strikethrough',
  },
  {
    name: 'inline-code',
    icon: 'code',
  },
  {
    name: 'heading-1',
    text: 'H1',
  },
  {
    name: 'heading-2',
    text: 'H2',
  },
  {
    name: 'heading-3',
    text: 'H3',
  },
  {
    name: 'heading-4',
    text: 'H4',
  },
  {
    name: 'heading-5',
    text: 'H5',
  },
  {
    name: 'heading-6',
    text: 'H6',
  },
  {
    name: 'quote',
    icon: 'quote-right',
  },
  {
    name: 'code-block',
    icon: 'file-code-o',
  },
  {
    name: 'image',
    icon: 'image',
  },
  {
    name: 'link',
    icon: 'link',
  },
  {
    name: 'mention',
    icon: 'at',
  },
  {
    name: 'unordered-list',
    icon: 'list-ul',
  },
  {
    name: 'ordered-list',
    icon: 'list-ol',
  },
  {
    name: 'color',
    value: '#FF0000',
    text: 'A',
  },
  {
    name: 'color',
    value: '#E6FF5C',
    text: 'A',
  },
  {
    name: 'checkbox-list',
    icon: 'check-square-o',
  },
  {
    name: 'divider',
    icon: 'minus',
  },
  {
    name: 'content',
    icon: 'plus',
  },
] as const;

type Item = (typeof STYLE_ITEMS)[number];
type StylesState = OnChangeStateEvent;

export interface ToolbarProps {
  stylesState: StylesState;
  editorRef?: React.RefObject<EnrichedTextInputInstance | null>;
  onOpenLinkModal: () => void;
  onSelectImage: () => void;
  onContentButtonPress?: () => void;
  selectionColor: string | null;
}

export const Toolbar: FC<ToolbarProps> = ({
  stylesState,
  editorRef,
  onOpenLinkModal,
  onSelectImage,
  onContentButtonPress,
  selectionColor,
}) => {
  const handlePress = (item: Item) => {
    const currentRef = editorRef?.current;
    if (!currentRef) return;

    switch (item.name) {
      case 'bold':
        editorRef.current?.toggleBold();
        break;
      case 'italic':
        editorRef.current?.toggleItalic();
        break;
      case 'underline':
        editorRef.current?.toggleUnderline();
        break;
      case 'strikethrough':
        editorRef.current?.toggleStrikeThrough();
        break;
      case 'inline-code':
        editorRef?.current?.toggleInlineCode();
        break;
      case 'heading-1':
        editorRef.current?.toggleH1();
        break;
      case 'heading-2':
        editorRef.current?.toggleH2();
        break;
      case 'heading-3':
        editorRef.current?.toggleH3();
        break;
      case 'heading-4':
        editorRef.current?.toggleH4();
        break;
      case 'heading-5':
        editorRef.current?.toggleH5();
        break;
      case 'heading-6':
        editorRef.current?.toggleH6();
        break;
      case 'code-block':
        editorRef?.current?.toggleCodeBlock();
        break;
      case 'quote':
        editorRef?.current?.toggleBlockQuote();
        break;
      case 'unordered-list':
        editorRef.current?.toggleUnorderedList();
        break;
      case 'ordered-list':
        editorRef.current?.toggleOrderedList();
        break;
      case 'link':
        onOpenLinkModal();
        break;
      case 'image':
        onSelectImage();
        break;
      case 'mention':
        editorRef.current?.startMention('@');
        break;
      case 'checkbox-list':
        editorRef.current?.toggleCheckList();
        break;
      case 'divider':
        editorRef.current?.addDividerAtNewLine();
        break;
      case 'content':
        onContentButtonPress?.();
        break;
    }
  };

  const handleColorButtonPress = (color: string) => {
    editorRef?.current?.setColor(color);
  };

  const getStyleStateByName = (item: Item) => {
    switch (item.name) {
      case 'color':
        return stylesState.colored;
      case 'bold':
        return stylesState.bold;
      case 'italic':
        return stylesState.italic;
      case 'underline':
        return stylesState.underline;
      case 'strikethrough':
        return stylesState.strikeThrough;
      case 'inline-code':
        return stylesState.inlineCode;
      case 'heading-1':
        return stylesState.h1;
      case 'heading-2':
        return stylesState.h2;
      case 'heading-3':
        return stylesState.h3;
      case 'heading-4':
        return stylesState.h4;
      case 'heading-5':
        return stylesState.h5;
      case 'heading-6':
        return stylesState.h6;
      case 'code-block':
        return stylesState.codeBlock;
      case 'quote':
        return stylesState.blockQuote;
      case 'unordered-list':
        return stylesState.unorderedList;
      case 'ordered-list':
        return stylesState.orderedList;
      case 'link':
        return stylesState.link;
      case 'image':
        return stylesState.image;
      case 'mention':
        return stylesState.mention;
      case 'checkbox-list':
        return stylesState.checkList;
      default:
        return {
          isActive: false,
          isConflicting: false,
          canNotBeApplied: false,
        };
    }
  };

  const renderItem = ({ item }: ListRenderItemInfo<Item>) => {
    const state = getStyleStateByName(item);

    return item.name === 'color' ? (
      <ToolbarColorButton
        onPress={handleColorButtonPress}
        color={item.value}
        text={item.text}
        isActive={state.isActive && selectionColor === item.value}
        disabled={state.canNotBeApplied}
      />
    ) : (
      <ToolbarButton
        {...item}
        disabled={state.canNotBeApplied}
        isActive={state.isActive}
        onPress={() => handlePress(item)}
      />
    );
  };

  const keyExtractor = (item: Item) =>
    item.name === 'color' ? item.value : item.name;

  return (
    <FlatList
      horizontal
      data={STYLE_ITEMS}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      style={styles.container}
    />
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
  },
});
