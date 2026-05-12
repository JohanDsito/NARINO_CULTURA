import carnavalimg from '@/assets/carnaval.png'
import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { EventCalendar } from '@/components/events/event-calendar'
import { useAuthStore } from '@/store/authStore'

export default function HomePage() {
  const { user, isAuthenticated } = useAuthStore()
  const isAdmin = user?.role === 'admin' || user?.role === 'cultural_manager'
  const accountPath =
    user?.role === 'admin'
      ? '/admin/dashboard'
      : user?.role === 'artist'
        ? '/dashboard/profile'
        : user?.role === 'cultural_manager'
          ? '/events'
          : '/marketplace'

  return (
    <div className="min-h-screen bg-background">
      <PageShell
        title="Nariño Cultura"
        description="Conecta con artistas, compra obras únicas, participa en subastas y descubre la agenda cultural de Nariño."
      >
        <section className="grid gap-6 lg:grid-cols-2 lg:items-center">
          <div className="space-y-4">
            <h2 className="text-5xl font-semibold leading-tight tracking-tight">
              Arte y tradición desde el corazón de Nariño
            </h2>
            <p className="max-w-2xl text-lg text-muted-foreground">
              Descubre artistas locales, explora obras originales, participa en subastas y sumérgete en la oferta cultural del departamento.
            </p>
            <div className="flex flex-wrap items-center gap-3">
              {isAuthenticated ? (
                <Button asChild aria-label="Ir a mi panel">
                  <Link to={accountPath}>Ir a mi panel</Link>
                </Button>
              ) : (
                <>
                  <Button asChild aria-label="Ir a login">
                    <Link to="/login">Iniciar sesión</Link>
                  </Button>
                  <Button variant="outline" asChild aria-label="Ir a registro">
                    <Link to="/register">Crear cuenta</Link>
                  </Button>
                </>
              )}
            </div>
            <Button variant="secondary" asChild aria-label="Explorar obras">
              <Link to="/artworks">Explorar obras</Link>
            </Button>
          </div>
          <div className="relative overflow-hidden rounded-xl border bg-card">
            <img
              src={carnavalimg}
              alt="Carnaval de Negros y Blancos: máscara y colores tradicionales"
              loading="lazy"
              className="h-[320px] w-full object-cover sm:h-[360px]"
            />
          </div>
        </section>

        <section className="mt-10 grid gap-4 md:grid-cols-3">
          <Card>
            <CardHeader>
              <CardTitle>Marketplace</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted-foreground">
                Compra obras y artesanías con un flujo de pago claro.
              </p>
              <Button variant="outline" asChild aria-label="Ir a marketplace">
                <Link to="/marketplace">Ver marketplace</Link>
              </Button>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle>Subastas</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted-foreground">
                Sigue subastas en tiempo real y participa con pujas.
              </p>
              <Button variant="outline" asChild aria-label="Ir a subastas">
                <Link to="/auctions">Ver subastas</Link>
              </Button>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle>Eventos</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <p className="text-sm text-muted-foreground">
                Descubre agenda cultural: conciertos, exposiciones y talleres.
              </p>
              <Button variant="outline" asChild aria-label="Ir a eventos">
                <Link to="/events">Ver eventos</Link>
              </Button>
            </CardContent>
          </Card>
        </section>

        {/* Sección de calendario de eventos */}
        <section className="mt-16 pb-8">
          <EventCalendar showCreateButton={isAdmin} />
        </section>
      </PageShell>
    </div>
  )
}
