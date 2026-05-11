import { useState } from 'react'
import { UserPlus, UserCheck, Globe, Music } from 'lucide-react'
import { FaInstagram } from 'react-icons/fa'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'

// Datos de ejemplo — luego reemplazar con datos reales de la API
const artist = {
  name:       'María Guerrero',
  artisticName: 'Mara Andina',
  discipline: 'Pintora · Artesana · Fotógrafa',
  bio:        'Artista nariñense con 12 años de trayectoria, especializada en técnicas mixtas que fusionan la iconografía del Carnaval de Negros y Blancos con el arte contemporáneo.',
  trajectory: 'Egresada de la Universidad de Nariño. Expositora en el Festival Iberoamericano de Teatro, Bienal de Arte de Bogotá y ferias internacionales en México y Ecuador.',
  photo:      'https://placehold.co/400x500/2D1B00/F0C060?text=Artista',
  followers:  1240,
  artworks:   38,
  sales:      94,
  years:      12,
  skills:     ['Óleo', 'Acuarela', 'Escultura', 'Fotografía'],
  softSkills: ['Creatividad', 'Colaboración', 'Gestión cultural'],
  interests:  ['Carnaval', 'Arte andino', 'Fotografía documental'],
  languages:  ['Español', 'Inglés intermedio'],
  instagram:  '#',
  website:    '#',
}

const sampleArtworks = [
  { id: 1, title: 'El Galeras Vigila', price: 1800000, status: 'DISPONIBLE',
    img: 'https://placehold.co/400x300/8B4513/F0DCC8?text=Obra+1' },
  { id: 2, title: 'Máscaras de Luz', price: 2400000, status: 'EN_SUBASTA',
    img: 'https://placehold.co/400x300/4A3320/F0C060?text=Obra+2' },
  { id: 3, title: 'Tejidos del Viento', price: 950000, status: 'DISPONIBLE',
    img: 'https://placehold.co/400x300/2E5E30/D4EBD5?text=Obra+3' },
]

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

export default function ArtistProfilePage() {
  const [following, setFollowing] = useState(false)

  return (
    <div className="min-h-screen bg-bg pt-16">

      {/* ── SECCIÓN SUPERIOR "About me" ── */}
      <section
        className="relative overflow-hidden px-6 md:px-16 py-16 md:py-24"
        style={{ background: '#2D1B00' }}
      >
        {/* Decoración radial dorada */}
        <div
          className="pointer-events-none absolute -top-20 -right-20 w-80 h-80 rounded-full"
          style={{ background: 'radial-gradient(circle, rgba(201,146,26,0.15) 0%, transparent 70%)' }}
        />

        <div className="max-w-5xl mx-auto grid md:grid-cols-2 gap-12 items-center relative z-10">

          {/* Columna izquierda — texto */}
          <div>
            <Badge variant="indigo" className="mb-4">Artista Verificado</Badge>

            <h1 className="font-display font-black text-oro-light leading-tight mb-1"
                style={{ fontSize: 'clamp(30px,6vw,50px)' }}>
              {artist.artisticName}
            </h1>

            <p className="font-accent italic text-tierra-light text-[22px] mb-6">
              {artist.discipline}
            </p>

            <p className="font-body text-[15px] leading-[1.65] mb-4"
               style={{ color: 'rgba(245,239,229,0.75)' }}>
              {artist.bio}
            </p>
            <p className="font-body text-[15px] leading-[1.65] mb-8"
               style={{ color: 'rgba(245,239,229,0.75)' }}>
              {artist.trajectory}
            </p>

            {/* Contacto */}
            <div className="flex flex-col gap-3">
              <p className="font-body font-bold text-[11px] tracking-widest uppercase text-text-muted">
                Contacto
              </p>
              <div className="flex gap-5">
                <a href={artist.instagram} aria-label="Instagram"
                   className="flex items-center gap-1.5 no-underline text-oro-light
                              font-body text-[13px] hover:text-oro transition-colors">
                  <FaInstagram size={16} /> Instagram
                </a>
                <a href={artist.website} aria-label="Sitio web"
                   className="flex items-center gap-1.5 no-underline text-oro-light
                              font-body text-[13px] hover:text-oro transition-colors">
                  <Globe size={16} /> Sitio web
                </a>
                <a href="#" aria-label="Música"
                   className="flex items-center gap-1.5 no-underline text-oro-light
                              font-body text-[13px] hover:text-oro transition-colors">
                  <Music size={16} /> Spotify
                </a>
              </div>
            </div>

            {/* Botón seguir */}
            <div className="mt-8">
              <Button
                variant={following ? 'secondary' : 'primary'}
                onClick={() => setFollowing(f => !f)}
                className="gap-2"
              >
                {following
                  ? <><UserCheck size={16} /> Siguiendo</>
                  : <><UserPlus  size={16} /> Seguir artista</>
                }
              </Button>
            </div>
          </div>

          {/* Columna derecha — foto */}
          <div className="flex justify-center md:justify-end">
            <div className="relative">
              {/* Marco decorativo dorado */}
              <div
                className="absolute inset-0 rounded-[20px]"
                style={{
                  border: '3px solid var(--oro)',
                  transform: 'translate(8px, 8px)',
                }}
              />
              <img
                src={artist.photo}
                alt={`Foto de ${artist.artisticName}`}
                loading="lazy"
                className="relative w-[280px] md:w-[340px] aspect-[4/5]
                           object-cover rounded-[20px] z-10"
              />
            </div>
          </div>

        </div>
      </section>

      {/* ── SECCIÓN MEDIA — Stats + Habilidades ── */}
      <section className="px-6 md:px-16 py-10">
        <div
          className="max-w-5xl mx-auto rounded-[24px] p-8 md:p-10"
          style={{ background: '#4A3320' }}
        >
          {/* Estadísticas */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-10">
            {[
              { label: 'Seguidores',        value: artist.followers },
              { label: 'Obras publicadas',  value: artist.artworks  },
              { label: 'Ventas',            value: artist.sales     },
              { label: 'Años de carrera',   value: artist.years     },
            ].map(({ label, value }) => (
              <div key={label} className="text-center">
                <p className="font-display font-bold text-oro"
                   style={{ fontSize: '28px' }}>
                  {value}
                </p>
                <p className="font-body font-medium text-[12px] text-text-muted mt-1">
                  {label}
                </p>
              </div>
            ))}
          </div>

          {/* Skills */}
          <div className="grid md:grid-cols-2 gap-8">
            <div>
              <p className="font-body font-bold text-[11px] tracking-widest uppercase
                            text-text-muted mb-3">
                Técnicas artísticas
              </p>
              <div className="flex flex-wrap gap-2">
                {artist.skills.map(s => (
                  <Badge key={s} variant="tierra">{s}</Badge>
                ))}
              </div>
            </div>
            <div>
              <p className="font-body font-bold text-[11px] tracking-widest uppercase
                            text-text-muted mb-3">
                Habilidades
              </p>
              <div className="flex flex-wrap gap-2">
                {artist.softSkills.map(s => (
                  <Badge key={s} variant="oro">{s}</Badge>
                ))}
              </div>
            </div>
          </div>

          {/* Idiomas e intereses */}
          <div className="mt-6 flex flex-wrap gap-2">
            {[...artist.languages, ...artist.interests].map(item => (
              <Badge key={item} variant="selva">{item}</Badge>
            ))}
          </div>
        </div>
      </section>

      {/* ── SECCIÓN PORTAFOLIO — Sus obras ── */}
      <section className="px-6 md:px-16 py-10 max-w-5xl mx-auto">
        {/* Título con línea dorada */}
        <div className="flex items-center gap-4 mb-8">
          <h2 className="font-display font-bold text-text-primary"
              style={{ fontSize: '28px', whiteSpace: 'nowrap' }}>
            Sus Obras
          </h2>
          <div className="flex-1 h-[2px]" style={{ background: 'var(--oro)' }} />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {sampleArtworks.map(artwork => (
            <Card key={artwork.id} className="p-0 overflow-hidden group">
              {/* Imagen con overlay */}
              <div className="relative aspect-[4/3] overflow-hidden rounded-t-card">
                <img
                  src={artwork.img}
                  alt={artwork.title}
                  loading="lazy"
                  className="w-full h-full object-cover transition-transform
                             duration-[350ms] ease-smooth group-hover:scale-105"
                />
                {/* Overlay hover */}
                <div className="absolute inset-0 bg-volcan/80 opacity-0 group-hover:opacity-100
                                transition-opacity duration-300 flex items-center justify-center">
                  <Button variant="gold" className="text-xs">Ver obra</Button>
                </div>
              </div>
              {/* Info */}
              <div className="p-4">
                <h3 className="font-display font-bold text-text-primary text-[15px] mb-1">
                  {artwork.title}
                </h3>
                <p className="font-body text-text-muted text-[12px] mb-2">
                  {artist.artisticName}
                </p>
                <div className="flex items-center justify-between">
                  <p className="font-body font-bold text-oro text-[15px]">
                    {formatPrice(artwork.price)}
                  </p>
                  <Badge variant={artwork.status === 'DISPONIBLE' ? 'selva' : 'indigo'}>
                    {artwork.status === 'DISPONIBLE' ? 'Disponible' : 'En subasta'}
                  </Badge>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </section>

    </div>
  )
}