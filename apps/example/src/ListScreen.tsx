import { useCallback, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import {
  LegendList,
  type LegendListRenderItemProps,
} from '@legendapp/list/react-native';
import {
  EnrichedText,
  type OnLinkPressEvent,
  type OnMentionPressEvent,
} from 'react-native-enriched';
import htmlStyle from './styles';

type Message = {
  id: string;
  isOwn: boolean;
  html: string;
};

const MESSAGE_COUNT = 1000;

const TEMPLATES = [
  (i: number) => `<html><p>Message ${i}</p></html>`,
  (i: number) =>
    `<html><p>Message ${i}: Lorem Ipsum is simply dummy text of the printing and typesetting industry. ` +
    "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.</p></html>",
  (i: number) =>
    `<html><p>Message ${i} with <b>bold</b>, <i>italic</i>, <u>underline</u> and <code>code</code>.</p></html>`,
  (i: number) =>
    `<html><p>Message ${i}: ask <mention text="@alex" type="user" indicator="@">@alex</mention> ` +
    `or open <a href="https://example.com/${i}">the link ${i}</a>.</p></html>`,
  (i: number) =>
    `<html><p>Message ${i}:</p><ul><li>First point</li><li>Second point that is long enough to wrap</li></ul></html>`,
  (i: number) =>
    `<html><h3>Message ${i}</h3><p>A heading and a paragraph.</p></html>`,
  (i: number) =>
    `<html><blockquote>Message ${i} quoted</blockquote><p>And the reply to it.</p></html>`,
  (i: number) => `Plain text message ${i} 👍`,
];

const MESSAGES: Message[] = Array.from({ length: MESSAGE_COUNT }, (_, i) => ({
  id: String(i),
  isOwn: i % 3 === 0,
  html: TEMPLATES[i % TEMPLATES.length]!(i),
}));

const keyExtractor = (item: Message) => item.id;

const getItemType = (item: Message) => (item.isOwn ? 'own' : 'other');

export default function ListScreen() {
  const [recycleItems, setRecycleItems] = useState(true);
  const [lastEvent, setLastEvent] = useState('Tap a link or a mention');

  const handleLinkPress = useCallback(({ url }: OnLinkPressEvent) => {
    setLastEvent(`Link: ${url}`);
  }, []);

  const handleMentionPress = useCallback(({ text }: OnMentionPressEvent) => {
    setLastEvent(`Mention: ${text}`);
  }, []);

  const handleLinkLongPress = useCallback(({ url }: OnLinkPressEvent) => {
    setLastEvent(`Link long press: ${url}`);
  }, []);

  // The bubble doesn't get the touches on a link or a mention
  const handleBubblePress = useCallback((id: string) => {
    setLastEvent(`Bubble press: ${id}`);
  }, []);

  const handleBubbleLongPress = useCallback((id: string) => {
    setLastEvent(`Bubble long press: ${id}`);
  }, []);

  const renderItem = useCallback(
    ({ item }: LegendListRenderItemProps<Message>) => (
      <View style={[styles.row, item.isOwn && styles.ownRow]}>
        <Pressable
          style={[styles.bubble, item.isOwn && styles.ownBubble]}
          onPress={() => handleBubblePress(item.id)}
          onLongPress={() => handleBubbleLongPress(item.id)}
        >
          <EnrichedText
            style={styles.text}
            htmlStyle={htmlStyle}
            onLinkPress={handleLinkPress}
            onLinkLongPress={handleLinkLongPress}
            onMentionPress={handleMentionPress}
          >
            {item.html}
          </EnrichedText>
        </Pressable>
      </View>
    ),
    [
      handleBubbleLongPress,
      handleBubblePress,
      handleLinkLongPress,
      handleLinkPress,
      handleMentionPress,
    ]
  );

  return (
    <View style={styles.screen}>
      <View style={styles.toolbar}>
        <Pressable
          onPress={() => setRecycleItems((value) => !value)}
          style={styles.toggle}
        >
          <Text style={styles.toggleText}>
            recycleItems: {recycleItems ? 'on' : 'off'}
          </Text>
        </Pressable>
        <Text style={styles.event} numberOfLines={1}>
          {lastEvent}
        </Text>
      </View>
      <LegendList
        // A new list when the recycling changes
        key={String(recycleItems)}
        data={MESSAGES}
        alignItemsAtEnd
        maintainScrollAtEnd
        initialScrollAtEnd
        renderItem={renderItem}
        keyExtractor={keyExtractor}
        getItemType={getItemType}
        estimatedItemSize={80}
        recycleItems={recycleItems}
        contentContainerStyle={styles.content}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#f2f2f7',
  },
  toolbar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 12,
  },
  toggle: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    backgroundColor: '#3a5bff',
  },
  toggleText: {
    color: 'white',
  },
  event: {
    flex: 1,
    color: '#555',
  },
  content: {
    paddingHorizontal: 12,
    paddingBottom: 24,
  },
  row: {
    paddingVertical: 4,
    alignItems: 'flex-start',
  },
  ownRow: {
    alignItems: 'flex-end',
  },
  bubble: {
    maxWidth: '80%',
    padding: 10,
    borderRadius: 12,
    backgroundColor: 'white',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#c7c7cc',
  },
  ownBubble: {
    backgroundColor: '#dbe4ff',
    borderColor: '#b4c3ff',
  },
  text: {
    fontSize: 16,
    color: '#111',
  },
});
