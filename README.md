# diario-rpi

Sitio web privado, generado con [Hugo](https://gohugo.io/) y el tema
[PaperMod](https://github.com/adityatelange/hugo-PaperMod), para leer un diario
personal escrito en Markdown. Se aloja en una Raspberry Pi y se sirve con Apache
detrás de autenticación.

Las entradas reales del diario no forman parte del repositorio: viven en la
Raspberry y Hugo las lee en el momento del build. Para desarrollar se usan las
entradas de prueba de `diario-ejemplo/`, que muestran los distintos elementos
de Markdown.

## Formato de las entradas

Un archivo por día, `AAAA-MM-DD.md`, sin front matter:

```markdown
2026-11-09
Texto de la entrada en Markdown...

Etiquetas: trabajo, familia
```

- **Fecha y título:** se toman del nombre del archivo. El título se genera en español
  ("Lunes, 9 de noviembre de 2026").
- **Primera línea:** la fecha. Si contiene la fecha del nombre del archivo, se omite al mostrar la entrada.
- **Etiquetas (opcional):** la última línea no vacía, si empieza con `Etiquetas:`.
  Separadas por comas; se guardan en minúsculas. La línea no se muestra en el texto.
- Los archivos originales nunca se modifican. Otros archivos de la carpeta se ignoran
  (los `.md` con otro nombre, con un aviso en el build).

## Cómo funciona

Las entradas **no** son contenido de Hugo: se montan como archivos crudos en
`assets/diario/`, y el *content adapter* `content/entradas/_content.gotmpl` las
convierte en páginas normales (título, fecha, etiquetas y texto). Así el tema
funciona sin modificarlo.

Del tema solo se sobrescriben dos archivos, en `layouts/`:

| Archivo | Cambio respecto a PaperMod |
|---|---|
| `_partials/post_nav_links.html` | "Anterior" = día anterior y "Siguiente" = día siguiente (el tema lo hace al revés) |
| `index.json` | El índice de búsqueda incluye las etiquetas |

## Requisitos

- Hugo **v0.168.0** (edición estándar), la misma versión en desarrollo y en producción.
- El tema es un submódulo de git:

```bash
git clone --recurse-submodules https://github.com/dp-weasel/diario-rpi.git
# o, en un clon existente:
git submodule update --init
```

## Desarrollo

```bash
hugo server            # http://localhost:1313, recarga al guardar
hugo build -e development --panicOnWarning   # comprobar que compila sin avisos
```

## Configuración

| Archivo | Uso |
|---|---|
| `config/_default/hugo.toml` | Común: idioma, tema y sus parámetros, etiquetas, búsqueda, menú, URLs `/AAAA/MM/DD/` |
| `config/development/module.toml` | `hugo server`: entradas de prueba de `diario-ejemplo/` |
| `config/production/module.toml` | `hugo build`: **ruta de la carpeta del diario** en la Raspberry |

## Despliegue en la Raspberry

Se despliega lo que está en `master` de GitHub. Desde el PC:

```bash
./scripts/deploy.sh
```

El script entra por `ssh rpi`, clona o actualiza el repo (con el submódulo del tema)
en `/opt/diario-rpi` y ejecuta `scripts/install.sh` (idempotente), que:

1. crea `/var/www/diario` (dueño `weasel`, grupo `www-data`, sin acceso para otros);
2. instala `diario-build.service` y `diario-build.path` en systemd;
3. genera el sitio (`scripts/build.sh`: build en carpeta temporal y luego `rsync`,
   así un build fallido no rompe el sitio publicado);
4. instala y activa el vhost de Apache `diario.raspi.lan`.

Después, cada vez que se guarda una entrada en la carpeta del diario,
`diario-build.path` lo detecta y regenera el sitio.

**Contraseña** (una sola vez, en la Raspberry; no se guarda en el repo):

```bash
sudo htpasswd -c /etc/apache2/diario.htpasswd weasel
```

**Si cambia la carpeta del diario**, actualizarla en dos sitios:
`config/production/module.toml` (montaje) y `deploy/systemd/diario-build.path` (`PathChanged`).

Comandos útiles en la Raspberry:

```bash
systemctl status diario-build.path            # ¿está vigilando la carpeta?
journalctl -u diario-build.service -n 20      # últimos builds
sudo systemctl start diario-build.service     # regenerar a mano
```

## Actualizar el tema

```bash
git -C themes/PaperMod fetch && git -C themes/PaperMod checkout <commit-o-tag>
hugo build -e development --panicOnWarning    # comprobar
git add themes/PaperMod && git commit -m "Actualizar PaperMod"
```

Una versión nueva del tema puede requerir una versión más nueva de Hugo
(ver `min_version` en `themes/PaperMod/theme.toml`) en el PC y en la Raspberry.

## Estructura

```
config/                    configuración por entorno
content/                   portada, búsqueda, archivo, etiquetas
content/entradas/_content.gotmpl   content adapter: entradas -> páginas
diario-ejemplo/            entradas de prueba (desarrollo)
layouts/                   las dos plantillas que sobrescriben al tema
static/                    archivos estáticos (imagen de prueba)
themes/PaperMod/           tema (submódulo de git)
deploy/                    vhost de Apache y unidades de systemd
scripts/                   build.sh, install.sh (Raspberry) y deploy.sh (PC)
```

## Licencia

[GPL-3.0](LICENSE). El tema PaperMod tiene licencia MIT.
