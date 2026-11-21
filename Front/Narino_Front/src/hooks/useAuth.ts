import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { authApi } from '@/api/auth.api'
import { syncCartToServer } from '@/hooks/useCartSync'
import { useAuthStore } from '@/store/authStore'
import type { LoginCredentials, RegisterData } from '@/types'
import { getArtistDashboardPath } from '@/utils/artistDiscipline'

export function useLogin() {
  const { setAuth } = useAuthStore()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (credentials: LoginCredentials) => authApi.login(credentials),
    onSuccess: ({ tokens, user }) => {
      // Nada de la sesión anterior (perfil "me", carrito...) debe sobrevivir
      queryClient.clear()
      setAuth(user, tokens.access, tokens.refresh)
      void syncCartToServer().then(() =>
        queryClient.invalidateQueries({ queryKey: ['server-cart'] }),
      )
      toast.success(`Bienvenido, ${user.first_name}`)

      const roleRoutes: Record<string, string> = {
        admin: '/admin/dashboard',
        artist: getArtistDashboardPath(user.id),
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
  const queryClient = useQueryClient()

  return async () => {
    await authApi.logout()
    logout()
    queryClient.clear()
    toast.success('Sesión cerrada exitosamente')
    navigate('/login')
  }
}
