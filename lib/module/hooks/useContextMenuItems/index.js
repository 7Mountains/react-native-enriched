"use strict";

import { useMemo } from 'react';
const useContextMenuItems = contextMenuItems => useMemo(() => contextMenuItems?.reduce((acc, item) => {
  if (item.visible !== false) {
    acc.push({
      text: item.text,
      key: item.key,
      iOSIcon: item.iOSIcon
    });
  }
  return acc;
}, []), [contextMenuItems]);
export default useContextMenuItems;
//# sourceMappingURL=index.js.map