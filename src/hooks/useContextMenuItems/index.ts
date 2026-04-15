import { useMemo } from 'react';
import type { ContextMenuItemConfig } from '../../EnrichedTextInputNativeComponent';
import type { ContextMenuItem } from '../../types';

const useContextMenuItems = (contextMenuItems: ContextMenuItem[] | undefined) =>
  useMemo(
    () =>
      contextMenuItems?.reduce<ContextMenuItemConfig[]>((acc, item) => {
        if (item.visible !== false) {
          acc.push({
            text: item.text,
            key: item.key,
            iOSIcon: item.iOSIcon,
          });
        }

        return acc;
      }, []),
    [contextMenuItems]
  );

export default useContextMenuItems;
