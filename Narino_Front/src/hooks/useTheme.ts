import { useMemo } from 'react'

import { useUiStore } from '@/store/uiStore'

export function useTheme() {
  const theme = useUiStore((s) => s.theme)
  const setTheme = useUiStore((s) => s.setTheme)

  return useMemo(() => ({ theme, setTheme }), [theme, setTheme])
}

