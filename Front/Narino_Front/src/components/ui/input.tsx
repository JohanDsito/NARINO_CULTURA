import { forwardRef } from 'react'
import type { InputHTMLAttributes } from 'react'
import { cn } from '@/utils'

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  ({ className, ...props }, ref) => (
    <input
      ref={ref}
      className={cn(
        'w-full bg-bg-card border border-border-strong rounded-input',
        'px-4 py-2.5 font-body text-[15px] text-text-primary',
        'transition-colors duration-[350ms] ease-smooth',
        'focus:outline-none focus:border-azul focus:ring-2 focus:ring-azul/25',
        'placeholder:text-text-muted',
        // Botón de archivo con el estilo de la app (el texto lo pone el navegador en su idioma)
        'file:mr-3 file:cursor-pointer file:rounded-full file:border-0 file:bg-azul-tint file:px-3 file:py-1 file:text-[13px] file:font-semibold file:text-azul',
        className
      )}
      {...props}
    />
  )
)
Input.displayName = 'Input'
