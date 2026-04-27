import { useEffect } from 'react'
import { useThemeStore, type Theme, getSystemTheme, watchSystemTheme } from '../store/themeStore'

/**
 * Hook para acceder y controlar el tema de la aplicación.
 * Sincroniza automáticamente con las variables CSS y localStorage.
 *
 * @returns {Object} theme: tema actual ('light' | 'dark'), toggle: función para cambiar tema
 *
 * @example
 * const { theme, toggle } = useTheme()
 * return (
 *   <button onClick={toggle}>
 *     {theme === 'light' ? '🌙' : '☀️'}
 *   </button>
 * )
 */
export function useTheme() {
  const theme = useThemeStore((state) => state.theme)
  const toggle = useThemeStore((state) => state.toggle)
  const setTheme = useThemeStore((state) => state.setTheme)

  // Sincronizar con preferencia del sistema al montar
  useEffect(() => {
    const systemTheme = getSystemTheme()
    const savedTheme = localStorage.getItem('nc-theme-store') as Theme | null

    // Si no hay tema guardado, usar el del sistema
    if (!savedTheme) {
      setTheme(systemTheme)
    }
  }, [setTheme])

  // Escuchar cambios en la preferencia del sistema
  useEffect(() => {
    const unwatch = watchSystemTheme((systemTheme) => {
      // Solo cambiar si no hay preferencia guardada del usuario
      if (!localStorage.getItem('nc-theme-store')) {
        setTheme(systemTheme)
      }
    })

    return () => {
      unwatch?.()
    }
  }, [setTheme])

  return { theme, toggle, setTheme }
}

/**
 * Hook para acceder solo al tema sin funciones de cambio.
 * Útil para componentes que solo necesitan leer el tema.
 */
export function useThemeValue(): Theme {
  return useThemeStore((state) => state.theme)
}
