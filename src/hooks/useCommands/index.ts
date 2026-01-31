import { useImperativeHandle, type RefObject } from 'react';
import type {
  ComponentType,
  EnrichedTextInputInstance,
  HtmlRequest,
} from '../../types';
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
  nativeRef: RefObject<ComponentType | null>,
  mentionIndicators: string[] | undefined,
  nextHtmlRequestId: RefObject<number>,
  pendingHtmlRequests: RefObject<Map<number, HtmlRequest>>
) =>
  useImperativeHandle(ref, () => {
    const typedRef = nativeRef?.current;
    return {
      ...typedRef,
      measureInWindow: (callback: MeasureInWindowOnSuccessCallback) => {
        nullthrows(ref?.current).measureInWindow(callback);
      },
      measure: (callback: MeasureOnSuccessCallback) => {
        nullthrows(ref?.current).measure(callback);
      },
      measureLayout: (
        relativeToNativeComponentRef: HostInstance | number,
        onSuccess: MeasureLayoutOnSuccessCallback,
        onFail?: () => void
      ) => {
        nullthrows(ref?.current).measureLayout(
          relativeToNativeComponentRef,
          onSuccess,
          onFail
        );
      },
      setNativeProps: (nativeProps: object) => {
        nullthrows(ref?.current).setNativeProps(nativeProps);
      },
      focus: () => {
        Commands.focus(nullthrows(typedRef));
      },
      blur: () => {
        Commands.blur(nullthrows(typedRef));
      },
      setValue: (value: string) => {
        Commands.setValue(nullthrows(typedRef), value);
      },
      getHTML: (prettify: boolean = false) =>
        new Promise<string>((resolve, reject) => {
          const requestId = nextHtmlRequestId.current++;
          pendingHtmlRequests.current.set(requestId, { resolve, reject });
          Commands.requestHTML(nullthrows(typedRef), requestId, prettify);
        }),
      toggleBold: () => {
        Commands.toggleBold(nullthrows(typedRef));
      },
      toggleItalic: () => {
        Commands.toggleItalic(nullthrows(typedRef));
      },
      toggleUnderline: () => {
        Commands.toggleUnderline(nullthrows(typedRef));
      },
      toggleStrikeThrough: () => {
        Commands.toggleStrikeThrough(nullthrows(typedRef));
      },
      toggleInlineCode: () => {
        Commands.toggleInlineCode(nullthrows(typedRef));
      },
      toggleH1: () => {
        Commands.toggleH1(nullthrows(typedRef));
      },
      toggleH2: () => {
        Commands.toggleH2(nullthrows(typedRef));
      },
      toggleH3: () => {
        Commands.toggleH3(nullthrows(typedRef));
      },
      toggleH4: () => {
        Commands.toggleH4(nullthrows(typedRef));
      },
      toggleH5: () => {
        Commands.toggleH5(nullthrows(typedRef));
      },
      toggleH6: () => {
        Commands.toggleH6(nullthrows(typedRef));
      },
      toggleCodeBlock: () => {
        Commands.toggleCodeBlock(nullthrows(typedRef));
      },
      toggleBlockQuote: () => {
        Commands.toggleBlockQuote(nullthrows(typedRef));
      },
      toggleOrderedList: () => {
        Commands.toggleOrderedList(nullthrows(typedRef));
      },
      toggleUnorderedList: () => {
        Commands.toggleUnorderedList(nullthrows(typedRef));
      },
      setLink: (start: number, end: number, text: string, url: string) => {
        Commands.addLink(nullthrows(typedRef), start, end, text, url);
      },
      setImage: (uri: string, width: number, height: number) => {
        Commands.addImage(nullthrows(typedRef), uri, width, height);
      },
      setMention: (
        indicator: string,
        text: string,
        attributes?: Record<string, string>
      ) => {
        // Codegen does not support objects as Commands parameters, so we stringify attributes
        const parsedAttributes = JSON.stringify(attributes ?? {});

        Commands.addMention(
          nullthrows(typedRef),
          indicator,
          text,
          parsedAttributes
        );
      },
      startMention: (indicator: string) => {
        if (!mentionIndicators?.includes(indicator)) {
          warnAboutMissconfiguredMentions(indicator);
        }

        Commands.startMention(nullthrows(typedRef), indicator);
      },
      setSelection: (start: number, end: number) => {
        Commands.setSelection(nullthrows(typedRef), start, end);
      },
      toggleCheckList: () => {
        Commands.toggleCheckList(nullthrows(typedRef));
      },
      setColor: (color: string) => {
        Commands.setColor(nullthrows(typedRef), color);
      },
      removeColor: () => {
        Commands.removeColor(nullthrows(typedRef));
      },
      addDividerAtNewLine: () =>
        Commands.addDividerAtNewLine(nullthrows(typedRef)),
      setParagraphAlignment: (alignment: string) => {
        Commands.setParagraphAlignment(nullthrows(typedRef), alignment);
      },
      scrollTo: (x: number, y: number, animated: boolean = false) => {
        Commands.scrollTo(nullthrows(typedRef), x, y, animated);
      },
      addContent: (
        text: string,
        type: string,
        src: string,
        headers: string,
        attributes: string
      ) => {
        Commands.addContent(
          nullthrows(typedRef),
          text,
          type,
          src,
          headers,
          attributes
        );
      },
    };
  }, [
    mentionIndicators,
    nextHtmlRequestId,
    pendingHtmlRequests,
    nativeRef,
    ref,
  ]);

export { useCommands };
