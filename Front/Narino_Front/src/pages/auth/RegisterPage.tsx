import { Link } from 'react-router-dom'
import { Mountain } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { RegisterForm } from '@/components/auth/register-form'

export default function RegisterPage() {
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
            Únete a nuestra comunidad de artistas, visitantes y gestores culturales para transformar el ecosistema artístico de Nariño.
          </p>

          <Button asChild className="w-fit text-base py-3 px-6" aria-label="Explorar artistas">
            <Link to="/artists">Conocer artistas</Link>
          </Button>
        </div>
      </div>

      {/* Right Section - Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center px-6 py-12 overflow-auto">
        <div className="w-full max-w-md">
          <div className="nc-card rounded-card p-8 shadow-card border border-border bg-bg-card">
            <h3 className="text-3xl font-extrabold text-center mb-8 text-text-primary">Crear cuenta</h3>

            <RegisterForm />

            <div className="mt-6 pt-6 border-t border-border text-center">
              <p className="text-sm text-text-secondary">
                ¿Ya tienes cuenta?{' '}
                <Link to="/login" className="text-azul font-semibold hover:underline">
                  Inicia sesión aquí
                </Link>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
