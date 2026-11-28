import { useLocation } from 'react-router-dom'

/** Muestra la ruta actual (data-testid="location") para verificar navegación en las pruebas. */
export function LocationProbe() {
  const location = useLocation()
  return <div data-testid="location">{location.pathname + location.search}</div>
}
