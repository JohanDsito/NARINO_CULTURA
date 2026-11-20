# Flujo de trabajo con Git Flow

El repositorio sigue **Git Flow**: cada cambio vive en su propia rama y entra por un *pull request* (PR) con el CI en verde.
Nadie sube cambios directo a `main` ni a `develop`.

## Ramas

| Rama | Para qué | Sale de | Entra a | Se despliega |
|---|---|---|---|---|
| `main` | Lo que está en producción. Cada fusión es una versión | — | — | **Sí**, Railway despliega cada push a `main` |
| `develop` | Integración: las funcionalidades terminadas que irán en la próxima versión | `main` (una vez) | — | No |
| `feature/<tema>` | Una funcionalidad o mejora | `develop` | `develop` | No |
| `release/<versión>` | Preparar una versión: pruebas finales, documentación y número de versión | `develop` | `main` **y** `develop` | Al fusionar en `main` |
| `hotfix/<tema>` | Arreglar un error que está en producción | `main` | `main` **y** `develop` | Al fusionar en `main` |

Nombres en minúsculas, con guiones y en español, por ejemplo `feature/recordatorios-eventos`, `release/1.1.0` o `hotfix/webhook-wompi`.

## Cómo se trabaja

### Una funcionalidad nueva

```bash
git switch develop && git pull
git switch -c feature/recordatorios-eventos
# ...cambios, commits pequeños por tema...
git push -u origin feature/recordatorios-eventos
# PR: feature/recordatorios-eventos → develop
```

### Una versión

```bash
git switch develop && git pull
git switch -c release/1.1.0
# solo ajustes finales: versión, documentación, correcciones menores
git push -u origin release/1.1.0
# PR: release/1.1.0 → main  (al fusionarlo se despliega)
git switch main && git pull
git tag -a v1.1.0 -m "Versión 1.1.0" && git push origin v1.1.0
# PR: main → develop, para que develop tenga lo que se ajustó en la versión
```

### Un error en producción

```bash
git switch main && git pull
git switch -c hotfix/webhook-wompi
# arreglo + test que lo demuestra
git push -u origin hotfix/webhook-wompi
# PR: hotfix/webhook-wompi → main  (al fusionarlo se despliega)
git tag -a v1.0.1 -m "Hotfix 1.0.1" && git push origin v1.0.1
# PR: main → develop, para que el arreglo no se pierda en la próxima versión
```

> El repositorio borra la rama al fusionar el PR. Por eso el regreso de un hotfix o una versión a `develop`
> se hace con un PR `main → develop`.

## Versiones

Se usa **versionado semántico** con etiquetas `vMAYOR.MENOR.PARCHE` sobre `main`:

- **PARCHE** (`v1.0.1`): un hotfix.
- **MENOR** (`v1.1.0`): una versión con funcionalidades nuevas que no rompen la API.
- **MAYOR** (`v2.0.0`): cambios que rompen el contrato con la web o la app.

## Commits

Mensajes en español con el formato `tipo(ámbito): descripción`, por ejemplo
`fix(payments): el webhook responde 400 con referencias ajenas`.

| Tipo | Uso |
|---|---|
| `feat` | Funcionalidad nueva |
| `fix` | Corrección de un error |
| `test` | Pruebas |
| `refactor` | Cambio interno sin cambiar el comportamiento |
| `ci` | Integración continua |
| `chore` | Mantenimiento: dependencias, configuración, archivos del repo |
| `docs` | Documentación |

Un commit es un solo tema. Si un mensaje necesita "y además…", probablemente son dos commits.

## Antes de abrir un PR

Correr lo mismo que corre el CI, en la carpeta del componente que se tocó:

| Componente | Comandos |
|---|---|
| Backend (`Backend/narinocultura_backend`) | `ruff check --config ../pyproject.toml .` · `python manage.py makemigrations --check --dry-run` · `python -m coverage run --rcfile=../pyproject.toml --source=. manage.py test apps` · `python -m coverage report --rcfile=../pyproject.toml --fail-under=95` · `python ../scripts/coverage_criticos.py coverage.json` (después de `coverage json`) |
| Web (`Front/Narino_Front`) | `npm run typecheck` · `npm run lint` · `npm test` · `npm run build` |
| App (`narino_mobile`) | `flutter analyze` · `flutter test` |

El CI de GitHub Actions cubre el **backend** (`.github/workflows/backend-ci.yml`) y la **web**
(`.github/workflows/frontend-ci.yml`): corre en los PR hacia `main` y `develop` y en cada push a esas ramas, solo cuando
cambia su carpeta. La app se verifica localmente con la tabla anterior.

> En Windows las rutas no distinguen mayúsculas y en Linux sí: un import `@/pages/auth/...` hacia una carpeta `Auth/`
> funciona en el equipo y rompe el build del despliegue. Para renombrar solo mayúsculas en Windows se usa un nombre
> intermedio: `git mv Auth auth_tmp && git mv auth_tmp auth`.

## Configuración del repositorio (la hace un administrador)

- Rama por defecto: `develop`, para que los PR nuevos apunten ahí.
- Proteger `main` y `develop`: PR obligatorio y check **Backend CI** obligatorio.
- En Railway, activar "Wait for CI" para que el despliegue espere al CI.
