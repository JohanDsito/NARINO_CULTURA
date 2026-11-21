import { Link } from 'react-router-dom'
import { Mountain } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { LoginForm } from '@/components/auth/login-form'

export default function LoginPage() {
  return (
    <div className="min-h-screen flex pt-16">
      {/* Left Section - Welcome */}
      <div className="hidden lg:flex lg:w-1/2 flex-col justify-center px-16 py-20">
        <div className="flex items-center gap-3 mb-16">
          <div className="nc-brand w-12 h-12 rounded-[14px] flex items-center justify-center">
            <Mountain size={24} color="white" />
          </div>
          <h1 className="font-display text-3xl font-extrabold text-text-primary">Nariño Cultura</h1>
        </div>

        <div className="space-y-8 max-w-lg">
          <div>
            <h2 className="text-6xl font-display font-extrabold text-text-primary mb-6">Te damos la bienvenida</h2>
            <div className="nc-serpentina h-1.5 w-24 rounded-full" aria-hidden></div>
          </div>

          <p className="text-lg text-text-secondary leading-relaxed">
            Nariño Cultura es la plataforma para impulsar el ecosistema artístico como artista en la ciudad de Pasto.
          </p>

          <Button asChild className="w-fit text-base py-3 px-6" aria-label="Explorar la plataforma">
            <Link to="/artworks">Explorar obras</Link>
          </Button>
        </div>
      </div>

      {/* Right Section - Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center px-6 py-12">
        <div className="w-full max-w-md">
          <div className="nc-card rounded-card p-8 shadow-card border border-border bg-bg-card">
            <h3 className="text-3xl font-extrabold text-center mb-8 text-text-primary">Iniciar sesión</h3>

            <LoginForm />

            <div className="mt-6 pt-6 border-t border-border text-center space-y-4">
              <p className="text-sm text-text-secondary">
                ¿No tienes cuenta?{' '}
                <Link to="/register" className="text-azul font-semibold hover:underline">
                  Crear una aquí
                </Link>
              </p>
              <Link
                to="/forgot-password"
                className="inline-block text-sm text-azul hover:underline font-medium"
              >
                ¿Olvidaste tu contraseña?
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
