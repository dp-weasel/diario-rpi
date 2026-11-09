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

## Estructura

```
config/       configuración por entorno
content/      portadas y entradas de prueba
layouts/      plantillas (sin tema externo)
assets/css/   estilos (modo claro/oscuro) y resaltado de código
static/       archivos estáticos (imagen de prueba)
```

## Licencia

[GPL-3.0](LICENSE)
