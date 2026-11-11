# diario-rpi

Sitio web privado para leer un diario personal escrito en Markdown, generado con
[Hugo](https://gohugo.io/) y el tema [PaperMod](https://github.com/adityatelange/hugo-PaperMod).
Pensado para un servidor pequeño (por ejemplo una Raspberry Pi) con Apache y
autenticación por usuario y contraseña.

- Las entradas se escriben como archivos Markdown sueltos, **sin front matter**.
- El sitio se regenera solo cada vez que se guarda una entrada.
- Búsqueda, archivo por año/mes y etiquetas.
- Modo claro/oscuro, adaptado al móvil.

Las entradas reales **no** forman parte del repositorio: viven en una carpeta del
servidor y Hugo las lee en el momento del build. Para desarrollar se usan las
entradas de prueba de `diario-ejemplo/`.

## Formato de las entradas

Un archivo por día, `AAAA-MM-DD.md`, sin front matter:

```markdown
2026-11-09
Texto de la entrada en Markdown...

Tags: trabajo, familia
```

- **Fecha y título:** se toman del nombre del archivo. El título se genera en el
  idioma del sitio ("Lunes, 9 de noviembre de 2026").
- **Primera línea:** si contiene la fecha del nombre del archivo, se omite al mostrar
  la entrada (no hace falta escribirla).
- **Etiquetas (opcional):** la última línea no vacía, si empieza con `Tags:` (también
  se acepta `Etiquetas:`). Separadas por comas; se guardan en minúsculas. La línea no
  se muestra en el texto.
- Los archivos originales nunca se modifican. Otros archivos de la carpeta se ignoran
  (los `.md` con otro nombre, con un aviso en el build).

## Cómo funciona

```
 carpeta del diario                 Hugo (build)                         Apache
 AAAA-MM-DD.md  ──montaje──►  assets/diario/  ──content adapter──►  sitio estático  ──►  https + contraseña
       │                                                               ▲
       └── al guardar una entrada, systemd (.path) dispara el build ───┘
```

Las entradas **no** son contenido de Hugo: se montan como archivos crudos en
`assets/diario/`, y el *content adapter* `content/entradas/_content.gotmpl` las
convierte en páginas normales (título, fecha, etiquetas y texto). Así el tema
funciona sin modificarlo.

Del tema solo se sobrescriben tres archivos, en `layouts/`:

| Archivo | Cambio respecto a PaperMod |
|---|---|
| `_partials/post_nav_links.html` | "Anterior" = día anterior y "Siguiente" = día siguiente (el tema lo hace al revés) |
| `index.json` | El índice de búsqueda incluye las etiquetas |
| `_partials/post_meta.html` | Vacío: sin la línea "fecha · tiempo de lectura" (el título ya es la fecha). Junto con `params.hideMeta` |

## Requisitos

**Para desarrollar:**

- Hugo **v0.168.0** o superior, edición estándar (ver `module.hugoVersion.min` en
  `config/_default/hugo.toml`). Conviene usar la misma versión que en el servidor.
- git.

**En el servidor:**

- Linux con systemd.
- Hugo (misma versión que en desarrollo), git y rsync.
- Apache 2.4 con los módulos `ssl`, `auth_basic`, `authn_file` y `headers`, y
  `htpasswd` (paquete `apache2-utils` en Debian/Ubuntu).
- Un certificado TLS para el nombre del sitio.
- Un nombre que resuelva a la IP del servidor (DNS local, `/etc/hosts`, etc.).

## Desarrollo

```bash
git clone --recurse-submodules <url-del-repo>
cd diario-rpi
hugo server                                  # http://localhost:1313, recarga al guardar
hugo build -e development --panicOnWarning   # comprobar que compila sin avisos
```

El tema es un submódulo de git marcado como `shallow`: se descarga solo el commit
fijado, sin su historial. En un clon existente sin el tema: `git submodule update --init`.

## Configuración por entorno

| Archivo | Uso |
|---|---|
| `config/_default/hugo.toml` | Común: URL, idioma, zona horaria, tema y sus parámetros, etiquetas, búsqueda, menú, URLs `/AAAA/MM/DD/` |
| `config/development/module.toml` | `hugo server`: entradas de prueba de `diario-ejemplo/` |
| `config/production/module.toml` | `hugo build`: **carpeta del diario** en el servidor |

## Adaptar a otra instalación

Los valores propios de cada instalación están escritos directamente en estos archivos.
La columna "Valor actual" es la instalación de referencia del repositorio.

| Qué | Valor actual | Dónde cambiarlo |
|---|---|---|
| **Carpeta de las entradas** | `/home/weasel/Documentos/dp` | `config/production/module.toml` (`source`) y `deploy/systemd/diario-build.path` (`PathChanged`) |
| **Nombre del sitio** | `diario.raspi.lan` | `config/_default/hugo.toml` (`baseURL`), `deploy/apache/diario.conf` (`ServerName`, `Redirect`) y el mensaje final de `scripts/install.sh` |
| **Certificado TLS** | `/etc/ssl/raspi-lab/raspi.lan.{crt,key}` | `deploy/apache/diario.conf` (`SSLCertificateFile`, `SSLCertificateKeyFile`) |
| **Usuario que genera el sitio** (debe poder leer la carpeta de las entradas) | `weasel` | `deploy/systemd/diario-build.service` (`User`) |
| **Carpeta del repositorio en el servidor** | `/opt/diario-rpi` | `scripts/deploy.sh` (`DIR`) y `deploy/systemd/diario-build.service` (`ExecStart`, `ReadWritePaths`) |
| **Carpeta del sitio publicado** | `/var/www/diario` | `scripts/install.sh` y `scripts/build.sh` (`DESTINO`), `deploy/apache/diario.conf` (`DocumentRoot`, `<Directory>`) y `deploy/systemd/diario-build.service` (`ReadWritePaths`) |
| **Archivo de contraseñas** | `/etc/apache2/diario.htpasswd` | `scripts/install.sh` (`HTPASSWD`) y `deploy/apache/diario.conf` (`AuthUserFile`) |
| **Grupo del servidor web** | `www-data` (Debian/Ubuntu) | `scripts/install.sh` y el comentario de `scripts/build.sh` |
| **Repositorio a desplegar** | `https://github.com/dp-weasel/diario-rpi.git` | `scripts/deploy.sh` (`REPO_URL`), si se usa un fork |
| **Host SSH del servidor** | `rpi` | Variable de entorno `DIARIO_HOST` al ejecutar `scripts/deploy.sh` |
| **Zona horaria** | `America/Argentina/Buenos_Aires` | `config/_default/hugo.toml` (`timeZone`) |
| **Idioma** (títulos, fechas, textos del tema) | `es` | `config/_default/hugo.toml` (`locale`, `defaultContentLanguage`) y nombres del menú |

Para comprobar que no quedó ningún valor viejo:

```bash
git grep -nE "<valor-viejo>" -- . ':!themes'
```

## Instalación en un servidor

Requisitos del servidor instalados y valores adaptados (sección anterior).

**Opción A: desde otra máquina, por SSH.** Despliega lo que está en `master` del
repositorio remoto:

```bash
DIARIO_HOST=<host-ssh> ./scripts/deploy.sh
```

El script clona (o actualiza) el repo con el submódulo del tema en el servidor y
ejecuta `scripts/install.sh`. El usuario SSH necesita `sudo`.

**Opción B: directamente en el servidor.**

```bash
sudo git clone --recurse-submodules --shallow-submodules <url-del-repo> /opt/diario-rpi
sudo chown -R "$USER": /opt/diario-rpi
/opt/diario-rpi/scripts/install.sh
```

`scripts/install.sh` es idempotente (se puede repetir en cada actualización) y:

1. crea la carpeta del sitio (dueño: el usuario que lo ejecuta; grupo: el del
   servidor web; sin acceso para otros usuarios);
2. instala y activa `diario-build.service` y `diario-build.path` en systemd;
3. genera el sitio (`scripts/build.sh`: build en una carpeta temporal y luego `rsync`,
   así un build fallido no rompe el sitio publicado);
4. instala y activa el vhost de Apache.

**Contraseña** (una sola vez, en el servidor; nunca se guarda en el repositorio):

```bash
sudo htpasswd -c /etc/apache2/diario.htpasswd <usuario>   # -c crea el archivo: solo la primera vez
sudo htpasswd /etc/apache2/diario.htpasswd <otro-usuario> # añadir más usuarios
```

Mientras no exista el archivo, el sitio responde con error y no muestra contenido.

## Operación

```bash
systemctl status diario-build.path            # ¿está vigilando la carpeta?
journalctl -u diario-build.service -n 20      # últimos builds (y avisos)
sudo systemctl start diario-build.service     # regenerar a mano
```

## Actualizar el tema

```bash
git -C themes/PaperMod fetch --depth 1 origin <commit-o-tag>
git -C themes/PaperMod checkout FETCH_HEAD
hugo build -e development --panicOnWarning    # comprobar
git add themes/PaperMod && git commit -m "Actualizar PaperMod"
```

Una versión nueva del tema puede requerir una versión más nueva de Hugo (ver
`min_version` en `themes/PaperMod/theme.toml`), en desarrollo y en el servidor.

## Estructura

```
config/                            configuración por entorno
content/                           portada, búsqueda, archivo, etiquetas
content/entradas/_content.gotmpl   content adapter: entradas -> páginas
diario-ejemplo/                    entradas de prueba (desarrollo)
layouts/                           las tres plantillas que sobrescriben al tema
static/                            archivos estáticos (imagen de prueba)
themes/PaperMod/                   tema (submódulo de git)
deploy/                            vhost de Apache y unidades de systemd
scripts/                           build.sh, install.sh (servidor) y deploy.sh (remoto)
```

## Licencia

[GPL-3.0](LICENSE). El tema PaperMod tiene licencia MIT.
