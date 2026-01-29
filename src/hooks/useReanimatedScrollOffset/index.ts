import { useEvent, useHandler, useSharedValue } from 'react-native-reanimated';
import type { OnScrollEvent } from '../../EnrichedTextInputNativeComponent';

type ScrollHandlers = {
  onScroll: (event: OnScrollEvent, context: Record<string, unknown>) => void;
};

function useReanimatedScrollHandler(
  handlers: ScrollHandlers,
  dependencies?: unknown[]
) {
  const { context, doDependenciesDiffer } = useHandler(handlers, dependencies);

  return useEvent<OnScrollEvent>(
    (event) => {
      'worklet';
      const { onScroll } = handlers;
      if (event.eventName.endsWith('onInputScroll')) {
        onScroll(event, context);
      }
    },
    ['onInputScroll'],
    doDependenciesDiffer
  );
}

const useReanimatedScrollOffset = () => {
  const scrollOffset = useSharedValue(0);

  const scrollHandler = useReanimatedScrollHandler(
    {
      onScroll: (event) => {
        'worklet';
        scrollOffset.set(event.contentOffset.y);
      },
    },
    [scrollOffset]
  );

  return { scrollOffset, scrollHandler };
};

export default useReanimatedScrollOffset;
