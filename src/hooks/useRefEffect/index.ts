import { useCallback, useRef } from 'react';

type CallbackRef<T> = (instance: T) => void;

export default function useRefEffect<TInstance>(
  effect: (instance: TInstance) => void | (() => void)
): CallbackRef<TInstance | null> {
  const cleanupRef = useRef<(() => void) | void>(undefined);

  return useCallback(
    (instance: TInstance | null) => {
      if (cleanupRef.current) {
        cleanupRef.current();
        cleanupRef.current = undefined;
      }

      if (instance !== null) {
        cleanupRef.current = effect(instance);
      }
    },
    [effect]
  );
}
