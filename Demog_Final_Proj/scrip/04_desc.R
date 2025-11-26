#****************************************************************************#
#************************************************************************************************#
#
#                          Trabajo final del curso de Demografía 2026-1
#                         Facultad de Ciencias UNAM
#                             Tabla de Mortalidad 2010, 2019, 2021
#
#         Creado por:               Arwen Yetzirah Ortiz N. y
#                                   Carlos Evnagelista C.
#         Fecha de creación:        04/11/2025
#         Actualizado por:          Arwen Yetzirah Ortiz N. y
#                                   Carlos Evnagelista C.
#         Fecha de actualización:   25/11/2025
#         Contacto:                 arwenort@ciencias.unam.mx
#                                   carlosevangelista@ciencias.unam.mx
#************************************************************************************************#
#************************************************************************************************#
# Preámbulo ----
## Limpieza de gráficas----
graphics.off()

## Limpieza de memoria
rm(list=ls())

## Carga de paquetes ----
library(readxl)
library(reshape2)
library(lubridate)
library(ggplot2)
library(data.table)
library(dplyr)

# Cargar la tabla de vida generada previamente
lt_output <- fread("data/tabla_mortalidad_guanajuato_2010_2019_2021.csv")

# Descomposición por edad de la diferencia de la e_0 entre períodos - Método de Arriaga
desc <- function(lx1, Lx1, lx2, Lx2, edad) {
  # Verificar que los vectores tengan la misma longitud
  if(length(lx1) != length(lx2) | length(Lx1) != length(Lx2)) {
    stop("Los vectores de entrada deben tener la misma longitud")
  }
  
  n <- length(lx1)
  diff <- numeric(n)
  
  # Calcular las contribuciones por edad
  for(i in 1:(n-1)) {
    # Término de efecto directo
    term1 <- (lx1[i]/lx1[1]) * ((Lx2[i]/lx2[i]) - (Lx1[i]/lx1[i]))
    
    # Término de efecto indirecto
    term2 <- (lx1[i]/lx1[1]) * ((lx2[i+1]/lx2[i]) - (lx1[i+1]/lx1[i])) * 
      (Lx2[i+1]/lx2[i+1])
    
    # Término de interacción
    term3 <- (lx1[i]/lx1[1]) * ((Lx2[i]/lx2[i]) - (Lx1[i]/lx1[i])) * 
      ((lx2[i+1]/lx2[i]) - (lx1[i+1]/lx1[i]))
    
    diff[i] <- term1 + term2 + term3
  }
  
  # Para el último grupo de edad
  diff[n] <- (lx1[n]/lx1[1]) * ((Lx2[n]/lx2[n]) - (Lx1[n]/lx1[n]))
  
  # Crear data.frame con los resultados
  resultado <- data.frame(
    edad = edad,
    contribucion = diff,
    contribucion_abs = abs(diff),
    porcentaje = (diff / sum(diff)) * 100
  )
  
  return(resultado)
}

# Preparar datos para la descomposición
descomposicion_datos <- list()

# Para cada sexo, realizar las comparaciones
for(s in c('m', 'f')) {
  
  # Obtener datos para cada año
  lt_2010 <- lt_output[sex == s & year == 2010][order(age)]
  lt_2019 <- lt_output[sex == s & year == 2019][order(age)]
  lt_2021 <- lt_output[sex == s & year == 2021][order(age)]
  
  # Verificar que tenemos datos para todos los años
  if(nrow(lt_2010) > 0 & nrow(lt_2019) > 0 & nrow(lt_2021) > 0) {
    
    # Comparación 2010-2019
    desc_2010_2019 <- desc(
      lx1 = lt_2010$lx,
      Lx1 = lt_2010$Lx,
      lx2 = lt_2019$lx,
      Lx2 = lt_2019$Lx,
      edad = lt_2010$age
    )
    
    # Comparación 2019-2021
    desc_2019_2021 <- desc(
      lx1 = lt_2019$lx,
      Lx1 = lt_2019$Lx,
      lx2 = lt_2021$lx,
      Lx2 = lt_2021$Lx,
      edad = lt_2019$age
    )
    
    # Guardar resultados
    descomposicion_datos[[paste0(s, "_2010_2019")]] <- desc_2010_2019
    descomposicion_datos[[paste0(s, "_2019_2021")]] <- desc_2019_2021
  }
}

# Preparar datos para la gráfica de descomposición
descomp_hombres_2010_2019 <- descomposicion_datos[["m_2010_2019"]]
descomp_mujeres_2010_2019 <- descomposicion_datos[["f_2010_2019"]]
descomp_hombres_2019_2021 <- descomposicion_datos[["m_2019_2021"]]
descomp_mujeres_2019_2021 <- descomposicion_datos[["f_2019_2021"]]

# Top 10 edades con mayor contribución absoluta para cada sexo y período
top_hombres_2010_2019 <- descomp_hombres_2010_2019[order(-descomp_hombres_2010_2019$contribucion_abs), ][1:10, ]
top_mujeres_2010_2019 <- descomp_mujeres_2010_2019[order(-descomp_mujeres_2010_2019$contribucion_abs), ][1:10, ]
top_hombres_2019_2021 <- descomp_hombres_2019_2021[order(-descomp_hombres_2019_2021$contribucion_abs), ][1:10, ]
top_mujeres_2019_2021 <- descomp_mujeres_2019_2021[order(-descomp_mujeres_2019_2021$contribucion_abs), ][1:10, ]

top_hombres_2010_2019$sexo <- "Hombres"
top_mujeres_2010_2019$sexo <- "Mujeres"
top_hombres_2019_2021$sexo <- "Hombres"
top_mujeres_2019_2021$sexo <- "Mujeres"

top_hombres_2010_2019$periodo <- "2010-2019"
top_mujeres_2010_2019$periodo <- "2010-2019"
top_hombres_2019_2021$periodo <- "2019-2021"
top_mujeres_2019_2021$periodo <- "2019-2021"

datos_descomp <- rbind(top_hombres_2010_2019, top_mujeres_2010_2019, top_hombres_2019_2021, top_mujeres_2019_2021)

# GRÁFICA DE DESCOMPOSICIÓN ARRIAGA - ESTILO "GAFIRA"
# Crear grupos de edad quinquenales
datos_descomp$grupo_edad <- cut(datos_descomp$edad, 
                                breaks = seq(0, 100, 5), 
                                labels = paste0(seq(0, 95, 5), "-", seq(4, 99, 5)),
                                right = FALSE)

# Agrupar por sexo, período y grupo de edad
datos_agrupados <- datos_descomp %>%
  group_by(sexo, periodo, grupo_edad) %>%
  summarise(
    contribucion_total = sum(contribucion),
    .groups = 'drop'
  )

# GRÁFICA 1: Estilo similar a la imagen con dos períodos
ggplot(datos_agrupados, aes(x = grupo_edad, y = contribucion_total, 
                            fill = contribucion_total > 0)) +
  geom_col(alpha = 0.8, width = 0.7) +
  facet_grid(sexo ~ periodo, scales = "free_x", space = "free_x") +
  scale_fill_manual(
    values = c("TRUE" = "#2E8B57", "FALSE" = "#CD5C5C"),
    labels = c("TRUE" = "Ganancia", "FALSE" = "Pérdida"),
    name = "Efecto"
  ) +
  labs(
    title = "Descomposición de Cambios en Esperanza de Vida\nGuanajuato 2010-2019 y 2019-2021",
    subtitle = "Contribución por grupos de edad quinquenales - Método de Arriaga",
    x = "Grupo de Edad",
    y = "Contribución (años)",
    caption = "Fuente: Elaboración propia con datos de INEGI"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 8, color = "gray50"),
    axis.title = element_text(size = 10),
    axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
    axis.text.y = element_text(size = 8),
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    legend.title = element_text(size = 10),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 10),
    strip.background = element_rect(fill = "gray90", color = NA)
  )

# GUARDAR DATOS EN CSV ----
# Convertir la lista a data.table y guardar en CSV
descomp_combined <- rbindlist(descomposicion_datos, idcol = "comparacion")
write.csv(descomp_combined, "data/descomposicion_arriaga_guanajuato.csv", row.names = FALSE)
#------------------------------FIN---------------------------------------------