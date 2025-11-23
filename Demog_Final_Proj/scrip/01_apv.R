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
#         Fecha de actualización:   17/11/2025
#         Contacto:                 arwenort@ciencias.unam.mx
#                                   carlosevangelista@ciencias.unam.mx
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

## Función expo (crecimiento exponencial) ----
expo <- function(N_0, N_T, t_0, t_T, t){
  dt <- decimal_date(as.Date(t_T)) - decimal_date(as.Date(t_0))
  r <- log(N_T/N_0)/dt
  h <- t - decimal_date(as.Date(t_0))
  N_h <- N_0 * exp(r*h)  
  return(N_h)
}

## Carga de tablas de datos ----
censos_pro <- fread("data/censos_pro.csv")

# Años persona vividos 2010 ----
# Preparar datos: unir poblaciones de 2010 y 2020
censos_wide <- dcast(censos_pro, age + sex ~ year, value.var = "pop")

# Calcular años persona vividos para 2010
censos_wide[, N_2010 := expo(`2010`, `2020`, 
                             t_0 = "2010-03-15", 
                             t_T = "2020-03-15", 
                             t = 2010.5)]

apv2010 <- censos_wide[, .(age, sex, N = N_2010)]
apv2010[, year := 2010]

# Gráfica pirámide 2010
ggplot(apv2010, aes(x = factor(age), y = ifelse(sex == "male", -N/1e6, N/1e6), fill = sex)) +
  geom_col(width = 0.7, alpha = 0.8) +
  coord_flip() +
  scale_y_continuous(
    labels = function(x) paste0(abs(x), "M"),
    breaks = scales::pretty_breaks(n = 8)
  ) +
  scale_fill_manual(
    values = c("male" = "#1f77b4", "female" = "#d62728"),
    labels = c("male" = "Hombres", "female" = "Mujeres")
  ) +
  labs(
    title = "Pirámide Poblacional 2010",
    subtitle = "Distribución por edad y sexo",
    x = "Grupo de edad",
    y = "Población mitad de año (millones)",
    fill = "Sexo",
    caption = "Fuente: INEGI"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
    axis.text.y = element_text(size = 8),
    panel.grid.major.y = element_blank()
  )

# Años persona vividos 2019 ----
censos_wide[, N_2019 := expo(`2010`, `2020`, 
                             t_0 = "2010-03-15", 
                             t_T = "2020-03-15", 
                             t = 2019.5)]

apv2019 <- censos_wide[, .(age, sex, N = N_2019)]
apv2019[, year := 2019]  

# Gráfica pirámide 2019 
ggplot(apv2019, aes(x = factor(age), y = ifelse(sex == "male", -N/1e6, N/1e6), fill = sex)) +
  geom_col(width = 0.7, alpha = 0.8) +
  coord_flip() +
  scale_y_continuous(
    labels = function(x) paste0(abs(x), "M"),
    breaks = scales::pretty_breaks(n = 8)
  ) +
  scale_fill_manual(
    values = c("male" = "#1f77b4", "female" = "#d62728"),
    labels = c("male" = "Hombres", "female" = "Mujeres")
  ) +
  labs(
    title = "Pirámide Poblacional 2019",
    subtitle = "Distribución por edad y sexo",
    x = "Grupo de edad",
    y = "Población mitad de año (millones)",
    fill = "Sexo",
    caption = "Fuente: INEGI"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
    axis.text.y = element_text(size = 8),
    panel.grid.major.y = element_blank()
  )

# Años persona vividos 2021 ----
censos_wide[, N_2021 := `2020` * 1.01]  

apv2021 <- censos_wide[, .(age, sex, N = N_2021)]
apv2021[, year := 2021]

# Gráfica pirámide 2021
ggplot(apv2021, aes(x = factor(age), y = ifelse(sex == "male", -N/1e6, N/1e6), fill = sex)) +
  geom_col(width = 0.7, alpha = 0.8) +
  coord_flip() +
  scale_y_continuous(
    labels = function(x) paste0(abs(x), "M"),
    breaks = scales::pretty_breaks(n = 8)
  ) +
  scale_fill_manual(
    values = c("male" = "#1f77b4", "female" = "#d62728"),
    labels = c("male" = "Hombres", "female" = "Mujeres")
  ) +
  labs(
    title = "Pirámide Poblacional 2021",
    subtitle = "Distribución por edad y sexo (proyección)",
    x = "Grupo de edad",
    y = "Población mitad de año (millones)",
    fill = "Sexo",
    caption = "Fuente: INEGI (proyección basada en 2020)"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
    plot.subtitle = element_text(hjust = 0.5, color = "gray40"),
    axis.text.y = element_text(size = 8),
    panel.grid.major.y = element_blank()
  )


# COMPARATIVA SEPARADA POR AÑO -
apv_comparison <- rbind(apv2010, apv2019, apv2021)

ggplot(apv_comparison, aes(x = factor(age), y = ifelse(sex == "male", -N/1e6, N/1e6), fill = sex)) +
  geom_col(alpha = 0.8, width = 0.7) +
  coord_flip() +
  facet_wrap(~ year, ncol = 3) +
  scale_y_continuous(
    labels = function(x) paste0(abs(x), "M"),
    breaks = scales::pretty_breaks(n = 6)
  ) +
  scale_fill_manual(
    values = c("male" = "steelblue", "female" = "coral"),
    labels = c("male" = "Hombres", "female" = "Mujeres")
  ) +
  labs(
    title = "Pirámides Poblacionales - Guanajuato 2010, 2019, 2021",
    x = "Edad",
    y = "Población (millones)",
    fill = "Sexo",
    caption = "Fuente: INEGI"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(hjust = 0.5, face = "bold"),
    strip.text = element_text(face = "bold"),
    panel.grid.major.y = element_blank()
  )

# Consolidar tablas 2010, 2019 y 2021 ----
apv <- rbind(apv2010, apv2019, apv2021)

# Guardar tabla APV ----
write.csv(apv, "data/apv.csv", row.names = FALSE)
 

#------------------------------FIN--------------------------------------

