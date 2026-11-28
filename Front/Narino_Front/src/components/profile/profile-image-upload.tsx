import { useRef, useState } from 'react'
import { Camera } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface ProfileImageUploadProps {
  currentUrl?: string
  name: string
  onUpload: (file: File) => Promise<unknown>
  isPending: boolean
  disabled?: boolean
}

export function ProfileImageUpload({
  currentUrl,
  name,
  onUpload,
  isPending,
  disabled,
}: ProfileImageUploadProps) {
  // La foto elegida y su vista previa viajan juntas: una no existe sin la otra
  const [picked, setPicked] = useState<{ file: File; preview: string } | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const displayUrl = picked?.preview ?? currentUrl ?? null
  const initial = name.charAt(0).toUpperCase()

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return
    if (picked) URL.revokeObjectURL(picked.preview)
    setPicked({ file: f, preview: URL.createObjectURL(f) })
  }

  const handleSave = async (selected: File) => {
    try {
      await onUpload(selected)
    } catch {
      // Quien sube (la mutación) ya avisa del error; se conserva la foto elegida para reintentar
      return
    }
    setPicked(null)
  }

  const handleCancel = (current: { preview: string }) => {
    URL.revokeObjectURL(current.preview)
    setPicked(null)
    // El input está siempre montado: solo cambia el botón que se muestra
    inputRef.current!.value = ''
  }

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="flex items-center gap-2 text-lg">
          <Camera size={18} />
          Foto de perfil
        </CardTitle>
      </CardHeader>
      <CardContent className="flex flex-col items-center gap-4">
        <div className="relative">
          <div className="h-24 w-24 overflow-hidden rounded-full ring-2 ring-border">
            {displayUrl ? (
              <img src={displayUrl} alt={name} className="h-full w-full object-cover" />
            ) : (
              <div className="flex h-full w-full items-center justify-center bg-tierra/10 text-3xl font-bold text-tierra">
                {initial}
              </div>
            )}
          </div>
          <button
            type="button"
            disabled={disabled || isPending}
            onClick={() => inputRef.current?.click()}
            className="absolute bottom-0 right-0 flex h-7 w-7 items-center justify-center rounded-full border border-border bg-bg shadow-sm transition-colors hover:bg-bg-subtle disabled:cursor-not-allowed disabled:opacity-50"
          >
            <Camera size={13} />
          </button>
        </div>

        <input
          ref={inputRef}
          type="file"
          accept="image/*"
          className="sr-only"
          onChange={handleFileChange}
        />

        {picked ? (
          <div className="flex w-full gap-2">
            <Button
              type="button"
              className="flex-1 text-sm"
              onClick={() => handleSave(picked.file)}
              disabled={isPending}
            >
              {isPending ? 'Subiendo…' : 'Guardar foto'}
            </Button>
            <Button
              type="button"
              variant="outline"
              className="text-sm"
              onClick={() => handleCancel(picked)}
              disabled={isPending}
            >
              Cancelar
            </Button>
          </div>
        ) : (
          <Button
            type="button"
            variant="outline"
            className="w-full text-sm"
            disabled={disabled || isPending}
            onClick={() => inputRef.current?.click()}
          >
            Cambiar foto
          </Button>
        )}
      </CardContent>
    </Card>
  )
}
