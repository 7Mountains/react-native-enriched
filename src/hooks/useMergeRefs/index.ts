import { useCallback, type Ref } from 'react';
import useRefEffect from '../useRefEffect';

export default function useMergeRefs<Instance>(
  ...refs: readonly (Ref<Instance> | null | undefined)[]
): React.RefCallback<Instance> {
  const refEffect = useCallback(
    (current: Instance) => {
      const cleanups = refs.map((ref) => {
        if (!ref) {
          return undefined;
        }

        if (typeof ref === 'function') {
          const cleanup = ref(current);

          return typeof cleanup === 'function'
            ? cleanup
            : () => {
                ref(null);
              };
        } else {
          (ref as React.RefObject<Instance | null>).current = current;

          return () => {
            (ref as React.RefObject<Instance | null>).current = null;
          };
        }
      });

      return () => {
        for (const cleanup of cleanups) {
          cleanup?.();
        }
      };
    },
    [refs]
  );

  return useRefEffect(refEffect);
}
