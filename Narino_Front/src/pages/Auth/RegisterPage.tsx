import { Link } from 'react-router-dom'
import { Mountain } from 'lucide-react'

import { Button } from '@/components/ui/button'
import { RegisterForm } from '@/components/auth/register-form'

export default function RegisterPage() {
  return (
    <div className="min-h-screen flex bg-background">
      {/* Left Section - Welcome */}
      <div className="hidden lg:flex lg:w-1/2 flex-col justify-center px-16 py-20 bg-gradient-to-br from-[#F7F3EE] via-[#F2F0EB] to-[#EDE8E1] dark:from-[#2A2016] dark:via-[#221C14] dark:to-[#1A1208]">
        <div className="flex items-center gap-3 mb-16">
          <div className="w-12 h-12 rounded-lg bg-tierra flex items-center justify-center">
            <Mountain size={24} color="white" />
          </div>
          <h1 className="font-display text-3xl font-bold text-tierra">Nariño Cultura</h1>
        </div>

        <div className="space-y-8 max-w-lg">
          <div>
            <h2 className="text-6xl font-display font-bold text-text-primary dark:text-text-primary mb-6">WELCOME !</h2>
            <div className="h-1.5 w-20 bg-tierra rounded"></div>
          </div>

          <p className="text-lg text-text-secondary dark:text-text-secondary leading-relaxed">
            Únete a nuestra comunidad de artistas, compradores y gestores culturales para transformar el ecosistema artístico de Nariño.
          </p>

          <Button asChild className="w-fit text-base py-3 px-6" aria-label="Explorar artistas">
            <Link to="/artists">Conocer artistas</Link>
          </Button>
        </div>
      </div>

      {/* Right Section - Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center px-6 py-12 overflow-auto bg-gradient-to-br from-[#B8704E] via-[#A66B4A] to-[#8B5A3C] dark:from-[#1E1710] dark:via-[#1A1410] dark:to-[#141008]">
        <div className="w-full max-w-md">
          <div className="rounded-2xl p-8 shadow-2xl border-2 border-oro-light bg-white dark:bg-bg-card dark:border-tierra">
            <h3 className="text-3xl font-semibold text-center mb-8 text-text-primary dark:text-text-primary">Sign up</h3>

            <RegisterForm />

            <div className="mt-6 pt-6 border-t border-border dark:border-border text-center">
              <p className="text-sm text-text-secondary dark:text-text-secondary">
                ¿Ya tienes cuenta?{' '}
                <Link to="/login" className="text-tierra dark:text-tierra-light font-semibold hover:text-tierra-light dark:hover:text-tierra">
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
