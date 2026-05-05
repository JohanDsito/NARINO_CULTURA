import { useMutation } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { authApi } from '@/api/auth.api'
import { useAuthStore } from '@/store/authStore'
import type { LoginCredentials, RegisterData } from '@/types/auth'

export function useLogin() {
  const { setAuth } = useAuthStore()
  const navigate = useNavigate()

  return useMutation({
    mutationFn: (credentials: LoginCredentials) => authApi.login(credentials),
    onSuccess: ({ tokens, user }) => {
      setAuth(user, tokens.access, tokens.refresh)
      toast.success(`Bienvenido, ${user.first_name}`)

      const roleRoutes: Record<string, string> = {
        admin: '/admin/dashboard',
        artist: '/dashboard/profile',
        cultural_manager: '/events',
        buyer: '/marketplace',
      }
      navigate(roleRoutes[user.role] ?? '/')
    },
    onError: () => {
      toast.error('Credenciales incorrectas. Verifica tu email y contraseña.')
    },
  })
}

export function useRegister() {
  const navigate = useNavigate()

  return useMutation({
    mutationFn: (data: RegisterData) => authApi.register(data),
    onSuccess: () => {
      toast.success('Cuenta creada. Revisa tu correo para verificar tu cuenta.')
      navigate('/login')
    },
    onError: () => {
      toast.error('Error al crear la cuenta. El email puede estar en uso.')
    },
  })
}

export function useLogout() {
  const { logout } = useAuthStore()
  const navigate = useNavigate()

  return async () => {
    await authApi.logout()
    logout()
    toast.success('Sesión cerrada exitosamente')
    navigate('/login')
  }
}
