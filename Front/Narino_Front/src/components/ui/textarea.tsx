import { forwardRef } from 'react'
import type { TextareaHTMLAttributes } from 'react'
import { cn } from '@/utils'

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(
    ({ className, ...props }, ref) => (
    <textarea
        ref={ref}
        className={cn(
        'w-full bg-bg-card border border-border-strong rounded-input',
        'px-4 py-2.5 font-body text-[15px] text-text-primary',
        'transition-colors duration-[350ms] ease-smooth',
        'focus:outline-none focus:border-azul focus:ring-2 focus:ring-azul/25',
        'placeholder:text-text-muted',
        'resize-vertical',
        className
        )}
        {...props}
    />
    )
)
Textarea.displayName = 'Textarea'
