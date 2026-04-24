import heroImg from '@/assets/hero.png'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { useTheme } from '@/hooks/useTheme'

export default function HomePage() {
  const { theme, setTheme } = useTheme()

  return (
    <div className="min-h-screen bg-background">
      <PageShell
        title="Nariño Cultura"
        description="Plataforma digital cultural para el ecosistema artístico del departamento de Nariño, Colombia."
        actions={
          <div className="flex flex-wrap items-center justify-end gap-2">
            <Button
              variant={theme === 'light' ? 'secondary' : 'outline'}
              onClick={() => setTheme('light')}
              aria-label="Activar tema claro"
            >
              Claro
            </Button>
            <Button
              variant={theme === 'dark' ? 'secondary' : 'outline'}
              onClick={() => setTheme('dark')}
              aria-label="Activar tema oscuro"
            >
              Oscuro
            </Button>
            <Button
              variant={theme === 'system' ? 'secondary' : 'outline'}
              onClick={() => setTheme('system')}
              aria-label="Usar tema del sistema"
            >
              Sistema
            </Button>
          </div>
        }
      >
        <section className="grid gap-6 lg:grid-cols-2 lg:items-center">
          <div className="space-y-4">
            <h2 className="text-4xl font-semibold leading-tight">
              Arte, tradición y creación viva desde el sur de Colombia
            </h2>
            <p className="text-base text-muted-foreground">
              Explora obras, sigue artistas, participa en subastas y descubre eventos culturales.
            </p>
            <div className="flex flex-wrap gap-3">
              <Button asChild aria-label="Ir a login">
                <a href="/login">Iniciar sesión</a>
              </Button>
              <Button variant="outline" asChild aria-label="Ir a registro">
                <a href="/register">Crear cuenta</a>
              </Button>
              <Button variant="secondary" asChild aria-label="Explorar obras">
                <a href="/artworks">Explorar obras</a>
              </Button>
            </div>
          </div>
          <div className="relative overflow-hidden rounded-xl border bg-card">
            <img
              src={heroImg}
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
                <a href="/marketplace">Ver marketplace</a>
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
                <a href="/auctions">Ver subastas</a>
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
                <a href="/events">Ver eventos</a>
              </Button>
            </CardContent>
          </Card>
        </section>
      </PageShell>
    </div>
  )
}

