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
  const scrollOffset = useSharedValue(0);
  const scrollHandler = useReanimatedScrollHandler({
    onScroll: event => {
      'worklet';

      scrollOffset.set(event.contentOffset.y);
    }
  }, [scrollOffset]);
  return {
    scrollOffset,
    scrollHandler
  };
};
export default useReanimatedScrollOffset;
//# sourceMappingURL=index.js.map