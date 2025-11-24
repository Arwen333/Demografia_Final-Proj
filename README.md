# Demografia_Final-Proj
Este repositorio constituye el proyecto final integral del curso Demografía 9213, representando un ejercicio académico exhaustivo dedicado al estudio, desarrollo y análisis avanzado de tablas de mortalidad mediante la aplicación de metodologías demográficas contemporáneas implementadas en el entorno de programación R.

El proyecto se enmarca dentro del campo de la demografía formal y la estadística actuarial, abordando uno de los instrumentos fundamentales para el análisis poblacional: la tabla de mortalidad. Esta herramienta demográfica no solo permite cuantificar los patrones de mortalidad de una población, sino que también proporciona insights valiosos sobre la estructura etaria, esperanza de vida y dinámica poblacional.
## 📊 Objetivos del Proyecto
- Construcción de tablas de mortalidad completas
- Análisis de patrones demográficos y mortalidad
- Implementación de métodos demográficos en R
- Visualización de resultados y tendencias

## 🛠️ Tecnologías Utilizadas
- **R** (lenguaje de programación)
- **RStudio** (entorno de desarrollo)
- Paquetes de R: 
  - `data.table` (análisis de datos)
  - `ggplot2` (visualizaciones)
  - `readxl` (manejo de datos)
 
## 🚀 Instalación y Uso

### Prerrequisitos
- R (versión 4.0 o superior)
- RStudio (recomendado)

### Ejecución
1. Clonar el repositorio:
git clone https://github.com/Arwen333/Demografia_Final-Proj/tree/main
2. Abrir el proyecto en RStudio
Abre RStudio

Ve a File > Open Project

Navega hasta la carpeta Demografia_Proyecto_Final

Selecciona el archivo .Rproj

3. Instalar dependencias:
source("scripts/instalacion_paquetes.R")

5. Ejecutar análisis en orden:
## 📂 Scripts de Análisis

| Script | Función | Enlace |
|--------|---------|--------|
| `00_pre_process.R` | Preprocesamiento | [Ver código](https://github.com/Arwen333/Demografia_Final-Proj/blob/main/Demog_Final_Proj/scrip/00_pre_process.R) |
| `01_apv.R` | Años persona vividos | [Ver código](https://github.com/Arwen333/Demografia_Final-Proj/blob/main/Demog_Final_Proj/scrip/01_apv.R) |
| `02_def.R` | Análisis de defunciones | [Ver código](https://github.com/Arwen333/Demografia_Final-Proj/blob/main/Demog_Final_Proj/scrip/02_def.R) |
| `03_lt.R` | Tablas de vida | [Ver código](https://github.com/Arwen333/Demografia_Final-Proj/blob/main/Demog_Final_Proj/scrip/03_lt.R) |
| `04_desc.R` | Descomposición Arriaga | [Ver código](https://github.com/Arwen333/Demografia_Final-Proj/blob/main/Demog_Final_Proj/scrip/04_desc.R) |
| `05_dm.R` | Decremento múltiple | [Ver código](https://github.com/Arwen333/Demografia_Final-Proj/blob/main/Demog_Final_Proj/scrip/05_dm.R) |

# Generar reporte PDF final
rmarkdown::render("scripts/reporte_final.Rmd", 
                  output_file = "../results/informe/reporte_final.pdf")
#📄 Licencia
Este proyecto es para fines académicos del curso Demografía 9213.
