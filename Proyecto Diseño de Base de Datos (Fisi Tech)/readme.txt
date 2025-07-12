# FISI TECH SOLUTIONS

## Trabajo Final – Grupo 4

Este repositorio contiene el entregable final del curso, desarrollado por el Grupo 4, bajo el nombre de consultora FISI TECH SOLUTIONS. Se ha empaquetado toda la información relevante del proyecto, incluyendo documentación técnica, scripts SQL, exportaciones de base de datos y archivos de la aplicación desarrollada.

## Integrantes

- [Nombre 1]
- [Nombre 2]
- [Nombre 3]
- [Nombre 4]
- [Nombre 5]

## Estructura del Repositorio

A continuación, se detallan las carpetas y archivos contenidos en este repositorio:

| Carpeta / Archivo                       | Descripción |
|----------------------------------------|-------------|
| `README.md`                            | Archivo principal con las instrucciones generales, estructura y forma de ejecución del proyecto. |
| `Entrega_Parcial_1/`                   | Contiene los entregables de la primera etapa del proyecto, incluyendo avances del modelo conceptual y primeras validaciones. |
| `Entrega_Parcial_2/`                   | Incluye los entregables de la segunda etapa, como el modelo lógico, scripts iniciales y revisión técnica. |
| `Informe_Corporativo.pdf`              | Documento corporativo con la presentación institucional de la consultora y el enfoque empresarial del proyecto. |
| `Informe_Tecnico.pdf`                  | Documento técnico con justificación del diseño, modelo de datos, decisiones tecnológicas y pruebas realizadas. |
| `Modelo_Conceptual/`                   | Archivos fuente del modelo entidad-relación (E-R), elaborados en herramientas como MySQL Workbench, PowerDesigner u otras. |
| `Modelo_Logico/`                       | Archivos del modelo lógico, representando la estructura de tablas normalizadas derivadas del modelo conceptual. |
| `Modelo_Fisico/`                       | Archivos del modelo físico listos para su implementación en el sistema gestor de bases de datos (MySQL). |
| `Scripts_BD/`                          | Contiene los scripts SQL organizados: creación de esquemas, usuarios, base de datos, objetos y carga de datos. |
| `Scripts_Programacion/`               | Scripts que implementan la lógica de negocio mediante procedimientos almacenados, funciones y disparadores. |
| `Scripts_Pruebas/`                    | Casos de prueba en SQL para verificar la funcionalidad del sistema: inserciones, consultas, validaciones, entre otros. |
| `Exportaciones_BD/`                   | Archivos `.sql` exportados directamente desde la base de datos. Útiles para restaurar el sistema rápidamente. |
| `Aplicacion/`                          | Archivos fuente de la aplicación desarrollada, con las interfaces, lógica de negocio y conexión a la base de datos. |

## Requisitos Previos

Antes de ejecutar el sistema o importar la base de datos, se debe contar con lo siguiente:

- Servidor de base de datos MySQL (recomendado: MySQL 8.0 o superior)
- Herramienta de gestión de bases de datos como:
  - MySQL Workbench
  - phpMyAdmin
  - DBeaver
- Opcional: servidor local como XAMPP o Laragon, si la aplicación es web

## Instrucciones para Importar la Base de Datos

1. Abrir el gestor de base de datos (ej. MySQL Workbench o phpMyAdmin).
2. Crear una nueva base de datos con el nombre indicado en los scripts (por ejemplo: `fisi_tech_db`).
3. Ejecutar en orden los siguientes archivos dentro de la carpeta `Scripts_BD/`:
    - `1_Creacion_Esquema.sql`
    - `2_Usuarios.sql`
    - `3_Creacion_Objetos.sql`
    - `4_Carga_Datos.sql`
4. (Opcional) Ejecutar los scripts dentro de `Scripts_Programacion/` para añadir procedimientos, funciones y triggers.
5. Usar los scripts de `Scripts_Pruebas/` para validar que la base de datos funciona correctamente.

También se puede utilizar el archivo de `Exportaciones_BD/` para importar la base de datos completa directamente en una sola operación.

## Aplicación

Dentro de la carpeta `Aplicacion/` se encuentra la solución implementada. Dependiendo del tipo de desarrollo (web, escritorio, etc.), se deberá seguir las instrucciones específicas incluidas en dicha carpeta para su ejecución.

## Contacto

Para consultas relacionadas con este proyecto, puede contactarse con cualquier miembro del Grupo 4, FISI TECH SOLUTIONS.
