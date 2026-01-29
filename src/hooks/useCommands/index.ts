import { useImperativeHandle, type RefObject } from 'react';
import type { ComponentType, EnrichedTextInputInstance } from '../../types';
import type {
  HostInstance,
  MeasureInWindowOnSuccessCallback,
  MeasureLayoutOnSuccessCallback,
  MeasureOnSuccessCallback,
} from 'react-native';
import { Commands } from '../../EnrichedTextInputNativeComponent';

const nullthrows = <T>(value: T | null | undefined): T => {
  if (value == null) {
    throw new Error('Unexpected null or undefined value');
  }

  return value;
};

const warnAboutMissconfiguredMentions = (indicator: string) => {
  console.warn(
    `Looks like you are trying to set a "${indicator}" but it's not in the mentionIndicators prop`
  );
};

const useCommands = (
  ref: RefObject<EnrichedTextInputInstance | null> | undefined,
  nativeRef: RefObject<ComponentType>,
  mentionIndicators: string[] | undefined,
  nextHtmlRequestId: RefObject<number>,
  pendingHtmlRequests: RefObject<
    Map<
      number,
      {
        resolve: (html: string) => void;
        reject: (error: Error) => void;
      }
    >
  >
) => {
  useImperativeHandle(ref, () => ({
    measureInWindow: (callback: MeasureInWindowOnSuccessCallback) => {
      nullthrows(nativeRef.current).measureInWindow(callback);
    },
    measure: (callback: MeasureOnSuccessCallback) => {
      nullthrows(nativeRef.current).measure(callback);
    },
    measureLayout: (
      relativeToNativeComponentRef: HostInstance | number,
      onSuccess: MeasureLayoutOnSuccessCallback,
      onFail?: () => void
    ) => {
      nullthrows(nativeRef.current).measureLayout(
        relativeToNativeComponentRef,
        onSuccess,
        onFail
      );
    },
    setNativeProps: (nativeProps: object) => {
      nullthrows(nativeRef.current).setNativeProps(nativeProps);
    },
    focus: () => {
      Commands.focus(nullthrows(nativeRef.current));
    },
    blur: () => {
      Commands.blur(nullthrows(nativeRef.current));
    },
    setValue: (value: string) => {
      Commands.setValue(nullthrows(nativeRef.current), value);
    },
    getHTML: (prettify: boolean = false) =>
      new Promise<string>((resolve, reject) => {
        const requestId = nextHtmlRequestId.current++;
        pendingHtmlRequests.current.set(requestId, { resolve, reject });
        Commands.requestHTML(
          nullthrows(nativeRef.current),
          requestId,
          prettify
        );
      }),
    toggleBold: () => {
      Commands.toggleBold(nullthrows(nativeRef.current));
    },
    toggleItalic: () => {
      Commands.toggleItalic(nullthrows(nativeRef.current));
    },
    toggleUnderline: () => {
      Commands.toggleUnderline(nullthrows(nativeRef.current));
    },
    toggleStrikeThrough: () => {
      Commands.toggleStrikeThrough(nullthrows(nativeRef.current));
    },
    toggleInlineCode: () => {
      Commands.toggleInlineCode(nullthrows(nativeRef.current));
    },
    toggleH1: () => {
      Commands.toggleH1(nullthrows(nativeRef.current));
    },
    toggleH2: () => {
      Commands.toggleH2(nullthrows(nativeRef.current));
    },
    toggleH3: () => {
      Commands.toggleH3(nullthrows(nativeRef.current));
    },
    toggleH4: () => {
      Commands.toggleH4(nullthrows(nativeRef.current));
    },
    toggleH5: () => {
      Commands.toggleH5(nullthrows(nativeRef.current));
    },
    toggleH6: () => {
      Commands.toggleH6(nullthrows(nativeRef.current));
    },
    toggleCodeBlock: () => {
      Commands.toggleCodeBlock(nullthrows(nativeRef.current));
    },
    toggleBlockQuote: () => {
      Commands.toggleBlockQuote(nullthrows(nativeRef.current));
    },
    toggleOrderedList: () => {
      Commands.toggleOrderedList(nullthrows(nativeRef.current));
    },
    toggleUnorderedList: () => {
      Commands.toggleUnorderedList(nullthrows(nativeRef.current));
    },
    setLink: (start: number, end: number, text: string, url: string) => {
      Commands.addLink(nullthrows(nativeRef.current), start, end, text, url);
    },
    setImage: (uri: string, width: number, height: number) => {
      Commands.addImage(nullthrows(nativeRef.current), uri, width, height);
    },
    setMention: (
      indicator: string,
      text: string,
      attributes?: Record<string, string>
    ) => {
      // Codegen does not support objects as Commands parameters, so we stringify attributes
      const parsedAttributes = JSON.stringify(attributes ?? {});

      Commands.addMention(
        nullthrows(nativeRef.current),
        indicator,
        text,
        parsedAttributes
      );
    },
    startMention: (indicator: string) => {
      if (!mentionIndicators?.includes(indicator)) {
        warnAboutMissconfiguredMentions(indicator);
      }

      Commands.startMention(nullthrows(nativeRef.current), indicator);
    },
    setSelection: (start: number, end: number) => {
      Commands.setSelection(nullthrows(nativeRef.current), start, end);
    },
    toggleCheckList: () => {
      Commands.toggleCheckList(nullthrows(nativeRef.current));
    },
    setColor: (color: string) => {
      Commands.setColor(nullthrows(nativeRef.current), color);
    },
    removeColor: () => {
      Commands.removeColor(nullthrows(nativeRef.current));
    },
    addDividerAtNewLine: () =>
      Commands.addDividerAtNewLine(nullthrows(nativeRef.current)),
    setParagraphAlignment: (alignment: string) => {
      Commands.setParagraphAlignment(nullthrows(nativeRef.current), alignment);
    },
    scrollTo: (x: number, y: number, animated: boolean = false) => {
      Commands.scrollTo(nullthrows(nativeRef.current), x, y, animated);
    },
  }));
};

export { useCommands };
