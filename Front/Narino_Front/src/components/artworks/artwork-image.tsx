import { useState } from 'react'
import { Palette } from 'lucide-react'

import type { SectionAccent } from '@/components/layout/page-shell'
import { cn } from '@/utils'

const PLACEHOLDER: Record<SectionAccent, { bg: string; icon: string }> = {
  azul: { bg: 'from-azul-tint to-naranja-tint', icon: 'text-azul' },
  tomate: { bg: 'from-tomate-tint to-naranja-tint', icon: 'text-tomate' },
  naranja: { bg: 'from-naranja-tint to-oro-tint', icon: 'text-naranja' },
  oro: { bg: 'from-oro-tint to-naranja-tint', icon: 'text-oro' },
  magenta: { bg: 'from-magenta-tint to-naranja-tint', icon: 'text-magenta' },
  verde: { bg: 'from-verde-tint to-azul-tint', icon: 'text-verde' },
}

interface ArtworkImageProps {
  src?: string | null
  alt: string
  /** Color de la sección: el recuadro sin foto usa su tinte (catálogo magenta, tienda naranja…) */
  accent?: SectionAccent
  className?: string
  iconSize?: number
}

/**
 * Imagen de una obra. Sin foto (o si no carga) muestra un recuadro con el tinte de la sección y una paleta,
 * como la app. Reemplaza las imágenes de relleno de placehold.co (marrones y externas).
 */
export function ArtworkImage({ src, alt, accent = 'magenta', className, iconSize = 36 }: ArtworkImageProps) {
  const [failed, setFailed] = useState(false)

  if (src && !failed) {
    return (
      <img
        src={src}
        alt={alt}
        loading="lazy"
        onError={() => setFailed(true)}
        className={cn('h-full w-full object-cover', className)}
      />
    )
  }

  const colors = PLACEHOLDER[accent]
  return (
    <div
      role="img"
      aria-label={alt}
      className={cn('flex h-full w-full items-center justify-center bg-gradient-to-br', colors.bg, className)}
    >
      <Palette size={iconSize} className={colors.icon} aria-hidden />
    </div>
  )
}
