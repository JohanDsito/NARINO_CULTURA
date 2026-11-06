import { useRef, useState } from 'react'
import { Camera } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface ProfileImageUploadProps {
  currentUrl?: string
  name: string
  onUpload: (file: File) => Promise<void>
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
  const [preview, setPreview] = useState<string | null>(null)
  const [file, setFile] = useState<File | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  const displayUrl = preview ?? currentUrl ?? null
  const initial = name.charAt(0).toUpperCase()

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0]
    if (!f) return
    setFile(f)
    if (preview) URL.revokeObjectURL(preview)
    setPreview(URL.createObjectURL(f))
  }

  const handleSave = async () => {
    if (!file) return
    await onUpload(file)
    setFile(null)
    setPreview(null)
  }

  const handleCancel = () => {
    if (preview) URL.revokeObjectURL(preview)
    setFile(null)
    setPreview(null)
    if (inputRef.current) inputRef.current.value = ''
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
              <div className="flex h-full w-full items-center justify-center bg-primary/10 text-3xl font-bold text-primary">
                {initial}
              </div>
            )}
          </div>
          <button
            type="button"
            disabled={disabled || isPending}
            onClick={() => inputRef.current?.click()}
            className="absolute bottom-0 right-0 flex h-7 w-7 items-center justify-center rounded-full border border-border bg-background shadow-sm transition-colors hover:bg-muted disabled:cursor-not-allowed disabled:opacity-50"
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

        {file ? (
          <div className="flex w-full gap-2">
            <Button
              type="button"
              className="flex-1 text-sm"
              onClick={handleSave}
              disabled={isPending}
            >
              {isPending ? 'Subiendo…' : 'Guardar foto'}
            </Button>
            <Button
              type="button"
              variant="outline"
              className="text-sm"
              onClick={handleCancel}
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
