import carnavalimg from '@/assets/carnaval.png'
import { Link } from 'react-router-dom'
import { ArrowRight, CalendarDays, Gavel, Palette, ShoppingBag, type LucideIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { EventCalendar } from '@/components/events/event-calendar'
import { useAuthStore } from '@/store/authStore'
import { getArtistDashboardPath } from '@/utils/artistDiscipline'

/** Accesos a cada sección con su color (como en la app): catálogo magenta, tienda naranja, subastas oro y eventos tomate. */
const SECTIONS: {
  to: string
  eyebrow: string
  title: string
  text: string
  cta: string
  icon: LucideIcon
  tint: string
  ink: string
}[] = [
  {
    to: '/artworks',
    eyebrow: 'Artes plásticas',
    title: 'Catálogo',
    text: 'Obras originales de pintores, escultores y fotógrafos nariñenses.',
    cta: 'Ver catálogo',
    icon: Palette,
    tint: 'bg-magenta-tint',
    ink: 'text-magenta',
  },
  {
    to: '/marketplace',
    eyebrow: 'Artesanos',
    title: 'Tienda',
    text: 'Compra directo al creador con pago seguro por Wompi.',
    cta: 'Ver tienda',
    icon: ShoppingBag,
    tint: 'bg-naranja-tint',
    ink: 'text-naranja',
  },
  {
    to: '/auctions',
    eyebrow: 'En vivo',
    title: 'Subastas',
    text: 'Sigue las subastas en tiempo real y participa con pujas.',
    cta: 'Ver subastas',
    icon: Gavel,
    tint: 'bg-oro-tint',
    ink: 'text-oro',
  },
  {
    to: '/events',
    eyebrow: 'Agenda',
    title: 'Eventos',
    text: 'Conciertos, exposiciones, talleres y ferias del departamento.',
    cta: 'Ver eventos',
    icon: CalendarDays,
    tint: 'bg-tomate-tint',
    ink: 'text-tomate',
  },
]

export default function HomePage() {
  const { user, isAuthenticated } = useAuthStore()
  const isAdmin = user?.role === 'admin' || user?.role === 'cultural_manager'
  const accountPath = (() => {
    if (user?.role === 'admin') return '/admin/dashboard'
    if (user?.role === 'artist') return user.id ? getArtistDashboardPath(user.id) : '/dashboard'
    if (user?.role === 'cultural_manager') return '/events'
    return '/marketplace'
  })()

  return (
    <div className="min-h-screen pt-16">
      <PageShell
        eyebrow="Arte · música · carnaval"
        accent="magenta"
        title="Nariño Cultura"
        description="Conecta con artistas, compra obras únicas, participa en subastas y descubre la agenda cultural de Nariño."
      >
        <section className="grid gap-8 lg:grid-cols-2 lg:items-center">
          <div className="space-y-5">
            <h2 className="text-4xl font-extrabold leading-tight text-text-primary md:text-5xl">
              Arte y tradición desde el corazón de Nariño
            </h2>
            <p className="max-w-2xl text-lg text-text-secondary">
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
              <Button variant="ghost" asChild aria-label="Explorar obras">
                <Link to="/artworks">Explorar obras</Link>
              </Button>
            </div>
          </div>
          <div className="nc-card relative overflow-hidden rounded-card border border-border bg-bg-card shadow-card">
            <img
              src={carnavalimg}
              alt="Carnaval de Negros y Blancos: máscara y colores tradicionales"
              loading="lazy"
              className="h-[320px] w-full object-cover sm:h-[360px]"
            />
          </div>
        </section>

        <section className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-4" aria-label="Secciones">
          {SECTIONS.map(({ to, eyebrow, title, text, cta, icon: Icon, tint, ink }) => (
            <Link key={to} to={to} className="group no-underline" aria-label={cta}>
              <Card className="flex h-full flex-col gap-3">
                <span className={`flex h-11 w-11 items-center justify-center rounded-full ${tint} ${ink}`}>
                  <Icon size={20} aria-hidden />
                </span>
                <div>
                  <p className={`nc-eyebrow ${ink}`}>{eyebrow}</p>
                  <h3 className="text-xl font-extrabold text-text-primary">{title}</h3>
                </div>
                <p className="flex-1 text-sm text-text-secondary">{text}</p>
                <span className={`inline-flex items-center gap-1 text-sm font-semibold ${ink}`}>
                  {cta}
                  <ArrowRight size={14} className="transition-transform group-hover:translate-x-0.5" aria-hidden />
                </span>
              </Card>
            </Link>
          ))}
        </section>

        {/* Sección de calendario de eventos */}
        <section className="mt-16 pb-8">
          <EventCalendar showCreateButton={isAdmin} />
        </section>
      </PageShell>
    </div>
  )
}
