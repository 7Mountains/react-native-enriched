"use strict";

import { useEvent, useHandler, useSharedValue } from 'react-native-reanimated';
function useReanimatedScrollHandler(handlers, dependencies) {
  const {
    context,
    doDependenciesDiffer
  } = useHandler(handlers, dependencies);
  return useEvent(event => {
    'worklet';

    const {
      onScroll
    } = handlers;
    if (event.eventName.endsWith('onInputScroll')) {
      onScroll(event, context);
    }
  }, ['onInputScroll'], doDependenciesDiffer);
}
const useReanimatedScrollOffset = () => {
  const scrollOffset = useSharedValue({
    contentOffset: {
      x: 0,
      y: 0
    },
    contentInset: {
      top: 0,
      left: 0,
      bottom: 0,
      right: 0
    },
    contentSize: {
      width: 0,
      height: 0
    },
    layoutMeasurement: {
      width: 0,
      height: 0
    },
    velocity: {
      x: 0,
      y: 0
    },
    target: -1
  });
  const scrollHandler = useReanimatedScrollHandler({
    onScroll: event => {
      'worklet';

      scrollOffset.set(event);
    }
  }, [scrollOffset]);
  return {
    scrollOffset,
    scrollHandler
  };
};
export default useReanimatedScrollOffset;
//# sourceMappingURL=index.js.map