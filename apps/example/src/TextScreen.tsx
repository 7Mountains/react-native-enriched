import { useCallback, useMemo, useState } from 'react';
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  type DimensionValue,
} from 'react-native';
import {
  EnrichedText,
  type OnLinkPressEvent,
  type OnMentionPressEvent,
} from 'react-native-enriched';
import htmlStyle from './styles';

type Sample = {
  title: string;
  html: string;
};

const LOREM =
  'Lorem Ipsum is simply dummy text of the printing and typesetting industry. ' +
  "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, " +
  'when an unknown printer took a galley of type and scrambled it to make a type specimen book.';

const SAMPLES: Sample[] = [
  { title: 'Plain text (no html)', html: LOREM },
  { title: 'Long paragraph', html: `<html><p>${LOREM}</p></html>` },
  { title: 'Short message', html: '<html><p>Ok 👍</p></html>' },
  {
    title: 'Inline styles',
    html:
      '<html><p>A <b>bold</b>, <i>italic</i>, <u>underlined</u> and <s>struck</s> text, ' +
      '<font color="#ff0000">a colored part</font> and <code>inline code</code>.</p></html>',
  },
  {
    title: 'Links and mentions',
    html:
      '<html><p>Ask <mention text="@alex" type="user" indicator="@">@alex</mention> in ' +
      '<mention text="#general" type="channel" indicator="#">#general</mention> or read ' +
      '<a href="https://example.com">the docs</a> first.</p></html>',
  },
  {
    title: 'Long word / url',
    html: '<html><p>https://example.com/a/very/long/path/that/does/not/have/any/spaces/to/break/at?query=1234567890</p></html>',
  },
  {
    title: 'Paragraphs',
    html: '<html><p>First paragraph.</p><p>Second paragraph.</p><p></p><p>After an empty one.</p></html>',
  },
  {
    title: 'Headings',
    html: '<html><h1>Heading 1</h1><h2>Heading 2</h2><h3>Heading 3</h3><p>Body text.</p></html>',
  },
  {
    title: 'Lists',
    html:
      '<html><ul><li>First bullet</li><li>Second bullet with a longer text that wraps to the next line</li></ul>' +
      '<ol><li>First step</li><li>Second step</li></ol></html>',
  },
  {
    title: 'Checklist',
    html: '<html><checklist checked="true">Done task</checklist><checklist checked="false">Open task</checklist></html>',
  },
  {
    title: 'Blockquote and code block',
    html:
      '<html><blockquote>A quote that is long enough to wrap to the second line.</blockquote>' +
      '<codeblock>const answer = 42;</codeblock></html>',
  },
  {
    title: 'Horizontal rule',
    html: '<html><p>Above</p><hr><p>Below</p></html>',
  },
];

const WIDTHS: { label: string; width: DimensionValue | undefined }[] = [
  { label: 'Bubble', width: undefined },
  { label: '100%', width: '100%' },
  { label: '70%', width: '70%' },
  { label: '45%', width: '45%' },
];

const MAX_EVENTS = 4;

const FONT_SIZES = [14, 16, 20];
const LINE_HEIGHTS = [0, 24, 32];
const NUMBERS_OF_LINES = [0, 1, 2, 3];
const ELLIPSIZE_MODES = ['tail', 'middle', 'head', 'clip'] as const;

type ChipsProps<T> = {
  label: string;
  values: readonly T[];
  selected: T;
  format?: (value: T) => string;
  onSelect: (value: T) => void;
};

const Chips = <T,>({
  label,
  values,
  selected,
  format = String,
  onSelect,
}: ChipsProps<T>) => (
  <View style={styles.chipsRow}>
    <Text style={styles.chipsLabel}>{label}</Text>
    {values.map((value) => (
      <Pressable
        key={format(value)}
        onPress={() => onSelect(value)}
        style={[styles.chip, value === selected && styles.chipSelected]}
      >
        <Text style={value === selected && styles.chipTextSelected}>
          {format(value)}
        </Text>
      </Pressable>
    ))}
  </View>
);

const formatZero = (value: number) => (value === 0 ? 'none' : String(value));

export default function TextScreen() {
  const [widthIndex, setWidthIndex] = useState(0);
  const [fontSize, setFontSize] = useState(16);
  const [lineHeight, setLineHeight] = useState(0);
  const [numberOfLines, setNumberOfLines] = useState(0);
  const [ellipsizeMode, setEllipsizeMode] =
    useState<(typeof ELLIPSIZE_MODES)[number]>('tail');
  const [comparesWithText, setComparesWithText] = useState(false);
  const [customHtml, setCustomHtml] = useState(
    `<html><p>Type <b>your own</b> html here.</p></html>`
  );
  const [isSelectable, setIsSelectable] = useState(false);
  const [events, setEvents] = useState<string[]>([]);

  const width = WIDTHS[widthIndex]!.width;

  const textStyle = useMemo(
    () => [styles.text, { fontSize }, lineHeight > 0 ? { lineHeight } : null],
    [fontSize, lineHeight]
  );

  const bubbleStyle = useMemo(
    () => [styles.bubble, width === undefined ? styles.shrink : { width }],
    [width]
  );

  const logEvent = useCallback((event: string) => {
    setEvents((previous) => [event, ...previous].slice(0, MAX_EVENTS));
  }, []);

  const handleLinkPressIn = useCallback(
    ({ url }: OnLinkPressEvent) => logEvent(`Link press in: ${url}`),
    [logEvent]
  );

  const handleLinkPressOut = useCallback(
    ({ url }: OnLinkPressEvent) => logEvent(`Link press out: ${url}`),
    [logEvent]
  );

  const handleLinkPress = useCallback(
    ({ url }: OnLinkPressEvent) => logEvent(`Link press: ${url}`),
    [logEvent]
  );

  const handleLinkLongPress = useCallback(
    ({ url }: OnLinkPressEvent) => logEvent(`Link long press: ${url}`),
    [logEvent]
  );

  const handleMentionPressIn = useCallback(
    ({ text }: OnMentionPressEvent) => logEvent(`Mention press in: ${text}`),
    [logEvent]
  );

  const handleMentionPressOut = useCallback(
    ({ text }: OnMentionPressEvent) => logEvent(`Mention press out: ${text}`),
    [logEvent]
  );

  const handleMentionPress = useCallback(
    ({ text, type, indicator }: OnMentionPressEvent) =>
      logEvent(`Mention press: ${text} (${type}, ${indicator})`),
    [logEvent]
  );

  const handleMentionLongPress = useCallback(
    ({ text }: OnMentionPressEvent) => logEvent(`Mention long press: ${text}`),
    [logEvent]
  );

  const samples = useMemo(
    () => [{ title: 'Custom html', html: customHtml }, ...SAMPLES],
    [customHtml]
  );

  return (
    <ScrollView
      style={styles.screen}
      contentContainerStyle={styles.content}
      keyboardShouldPersistTaps="handled"
    >
      <Chips
        label="Width"
        values={WIDTHS.map((_, index) => index)}
        selected={widthIndex}
        format={(index) => WIDTHS[index]!.label}
        onSelect={setWidthIndex}
      />
      <Chips
        label="Font size"
        values={FONT_SIZES}
        selected={fontSize}
        onSelect={setFontSize}
      />
      <Chips
        label="Line height"
        values={LINE_HEIGHTS}
        selected={lineHeight}
        format={formatZero}
        onSelect={setLineHeight}
      />
      <Chips
        label="Lines"
        values={NUMBERS_OF_LINES}
        selected={numberOfLines}
        format={formatZero}
        onSelect={setNumberOfLines}
      />
      <Chips
        label="Ellipsize"
        values={ELLIPSIZE_MODES}
        selected={ellipsizeMode}
        onSelect={setEllipsizeMode}
      />
      <Chips
        label="Compare"
        values={[false, true]}
        selected={comparesWithText}
        format={(value) => (value ? 'with Text' : 'off')}
        onSelect={setComparesWithText}
      />

      <Chips
        label="Selectable"
        values={[false, true]}
        selected={isSelectable}
        format={(value) => (value ? 'on' : 'off')}
        onSelect={setIsSelectable}
      />

      <Text style={styles.event}>
        {events.length > 0 ? events.join('\n') : 'Tap a link or a mention'}
      </Text>

      <TextInput
        multiline
        value={customHtml}
        onChangeText={setCustomHtml}
        style={styles.htmlInput}
        autoCapitalize="none"
        autoCorrect={false}
      />

      {samples.map(({ title, html }) => (
        <View key={title} style={styles.sample}>
          <Text style={styles.sampleTitle}>{title}</Text>
          <View style={bubbleStyle}>
            <EnrichedText
              style={textStyle}
              htmlStyle={htmlStyle}
              numberOfLines={numberOfLines}
              ellipsizeMode={ellipsizeMode}
              selectable={isSelectable}
              onLinkPressIn={handleLinkPressIn}
              onLinkPressOut={handleLinkPressOut}
              onLinkPress={handleLinkPress}
              onLinkLongPress={handleLinkLongPress}
              onMentionPressIn={handleMentionPressIn}
              onMentionPressOut={handleMentionPressOut}
              onMentionPress={handleMentionPress}
              onMentionLongPress={handleMentionLongPress}
            >
              {html}
            </EnrichedText>
          </View>
          {comparesWithText && (
            <View style={bubbleStyle}>
              <Text
                style={textStyle}
                numberOfLines={numberOfLines}
                ellipsizeMode={ellipsizeMode}
              >
                {html.replace(/<[^>]+>/g, '')}
              </Text>
            </View>
          )}
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#f2f2f7',
  },
  content: {
    padding: 16,
    gap: 8,
  },
  chipsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    gap: 6,
  },
  chipsLabel: {
    width: 80,
    fontWeight: '600',
  },
  chip: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    backgroundColor: '#e0e0e6',
  },
  chipSelected: {
    backgroundColor: '#3a5bff',
  },
  chipTextSelected: {
    color: 'white',
  },
  event: {
    marginTop: 8,
    color: '#555',
  },
  htmlInput: {
    minHeight: 60,
    padding: 8,
    borderRadius: 8,
    backgroundColor: 'white',
    fontFamily: 'monospace',
    fontSize: 12,
  },
  sample: {
    marginTop: 12,
    gap: 4,
  },
  sampleTitle: {
    fontSize: 12,
    color: '#666',
  },
  bubble: {
    padding: 10,
    borderRadius: 12,
    backgroundColor: 'white',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#c7c7cc',
  },
  shrink: {
    alignSelf: 'flex-start',
    maxWidth: '80%',
  },
  text: {
    color: '#111',
  },
});
