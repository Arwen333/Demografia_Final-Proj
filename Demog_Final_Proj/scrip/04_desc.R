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
#         Fecha de actualización:   12/11/2025
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
    
    # Comparación 2010 vs 2021
    desc_2010_2021 <- desc(
      lx1 = lt_2010$lx,
      Lx1 = lt_2010$Lx,
      lx2 = lt_2021$lx,
      Lx2 = lt_2021$Lx,
      edad = lt_2010$age
    )
    
    # Guardar resultados
    descomposicion_datos[[paste0(s, "_2010_2021")]] <- desc_2010_2021
  }
}

# Preparar datos para la gráfica de descomposición
descomp_hombres <- descomposicion_datos[["m_2010_2021"]]
descomp_mujeres <- descomposicion_datos[["f_2010_2021"]]

# Top 10 edades con mayor contribución absoluta para cada sexo
top_hombres <- descomp_hombres[order(-descomp_hombres$contribucion_abs), ][1:10, ]
top_mujeres <- descomp_mujeres[order(-descomp_mujeres$contribucion_abs), ][1:10, ]

top_hombres$sexo <- "Hombres"
top_mujeres$sexo <- "Mujeres"
datos_descomp <- rbind(top_hombres, top_mujeres)

# GRÁFICA DE DESCOMPOSICIÓN ARRIAGA ----
ggplot(datos_descomp, aes(x = reorder(factor(edad), contribucion_abs), y = contribucion, 
                          fill = contribucion > 0)) +
  geom_col(alpha = 0.8, width = 0.7) +
  facet_wrap(~ sexo, nrow = 1, scales = "free_x") +
  scale_fill_manual(values = c("TRUE" = "#2E8B57", "FALSE" = "#CD5C5C"),
                    labels = c("TRUE" = "Aumento esperanza", "FALSE" = "Disminución esperanza"),
                    name = "Contribución") +
  labs(title = "Descomposición de Cambios en Esperanza de Vida\nGuanajuato 2010-2021",
       subtitle = "Método de Arriaga - Top 10 edades con mayor contribución",
       x = "Edad",
       y = "Contribución (años)",
       caption = "Fuente: Elaboración propia con datos de INEGI") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 9, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 7, color = "gray50"),
    axis.title = element_text(size = 9),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    axis.text.y = element_text(size = 8),
    legend.position = "bottom",
    legend.text = element_text(size = 8),
    legend.title = element_text(size = 9),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    strip.text = element_text(face = "bold", size = 10)
  )

# GUARDAR DATOS EN CSV ----
# Convertir la lista a data.table y guardar en CSV
descomp_combined <- rbindlist(descomposicion_datos, idcol = "comparacion")
write.csv(descomp_combined, "data/descomposicion_arriaga_guanajuato.csv", row.names = FALSE)
#------------------------------FIN---------------------------------------------
