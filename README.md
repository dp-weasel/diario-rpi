# diario-rpi

Sitio web privado, generado con [Hugo](https://gohugo.io/), para leer un diario
personal escrito en Markdown. Se aloja en una Raspberry Pi y se sirve con Apache
detrás de autenticación.

Las entradas reales del diario no forman parte del repositorio: viven en la
Raspberry y Hugo las lee en el momento del build. Para desarrollar se usan las
entradas de prueba de `content/entradas/`, que muestran los distintos elementos
de Markdown.

## Formato de las entradas

- Un archivo por día: `AAAA-MM-DD.md`.
- Sin front matter: la fecha se toma del nombre del archivo y el título se genera
  a partir de ella, en español ("Lunes, 9 de noviembre de 2026").
- La primera línea es la fecha. Si contiene la fecha del nombre del archivo, se omite
  al mostrar la entrada (el archivo no se modifica).

## Requisitos

- Hugo **v0.168.0** (edición estándar), la misma versión en desarrollo y en producción.

## Desarrollo

```bash
hugo server            # http://localhost:1313, recarga al guardar
hugo build -e development --panicOnWarning   # comprobar que compila sin avisos
```

## Configuración

| Archivo | Uso |
|---|---|
| `config/_default/hugo.toml` | Común: idioma, fechas desde el nombre del archivo, URLs `/AAAA/MM/DD/` |
| `config/development/hugo.toml` | `hugo server`: usa las entradas de prueba de `content/entradas/` |
| `config/production/hugo.toml` | `hugo build`: **ruta de la carpeta del diario** en la Raspberry |

En producción, las entradas de prueba no se incluyen: solo se toman las portadas
(`_index.md`) del repositorio y las entradas reales de la carpeta configurada.

## Despliegue en la Raspberry

Se despliega lo que está en `master` de GitHub. Desde el PC:

```bash
./scripts/deploy.sh
```

El script entra por `ssh rpi`, clona o actualiza el repo en `/opt/diario-rpi` y ejecuta
`scripts/install.sh` (idempotente), que:

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
`config/production/hugo.toml` (montaje) y `deploy/systemd/diario-build.path` (`PathChanged`).

Comandos útiles en la Raspberry:

```bash
systemctl status diario-build.path            # ¿está vigilando la carpeta?
journalctl -u diario-build.service -n 20      # últimos builds
sudo systemctl start diario-build.service     # regenerar a mano
```

## Estructura

```
config/       configuración por entorno
content/      portadas y entradas de prueba
layouts/      plantillas (sin tema externo)
assets/css/   estilos (modo claro/oscuro) y resaltado de código
static/       archivos estáticos (imagen de prueba)
deploy/       vhost de Apache y unidades de systemd
scripts/      build.sh, install.sh (Raspberry) y deploy.sh (PC)
```

## Licencia

[GPL-3.0](LICENSE)
