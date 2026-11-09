# diario-rpi

Sitio web privado, generado con [Hugo](https://gohugo.io/), para leer un diario
personal escrito en Markdown. Se aloja en una Raspberry Pi y se sirve con Apache
detrás de autenticación.

> Este repositorio contiene **solo el código del sitio** (configuración, plantillas,
> estilos y scripts de despliegue). Las entradas reales del diario **no** forman
> parte del repositorio: viven en la Raspberry y Hugo las lee en el momento del build.
> Para desarrollar se usan entradas ficticias en `ejemplos/`.

## Formato de las entradas

- Un archivo por día: `AAAA-MM-DD.md`.
- La primera línea es la fecha (se omite al mostrar la entrada).
- Sin front matter: la fecha se toma del nombre del archivo y el título se genera a partir de ella.

## Requisitos

- Hugo **v0.168.0** (edición estándar), la misma versión en desarrollo y en producción.

## Estado

En construcción.

## Licencia

[GPL-3.0](LICENSE)
