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

# Función expo simplificada ----
expo <- function(N_0, N_T, t_0, t_T, t){
  # Convertir fechas a años decimales manualmente
  date_to_decimal <- function(date_str) {
    date <- as.Date(date_str)
    year <- as.numeric(format(date, "%Y"))
    start <- as.Date(paste0(year, "-01-01"))
    end <- as.Date(paste0(year + 1, "-01-01"))
    year + as.numeric(date - start) / as.numeric(end - start)
  }
  
  dt <- date_to_decimal(t_T) - date_to_decimal(t_0)
  r <- log(N_T/N_0)/dt
  h <- t - date_to_decimal(t_0)
  N_0 * exp(r*h)  
}

# Función lt_abr ----
lt_abr <- function(x, mx, sex, l0 = 1e5) {
  n <- c(diff(x), NA)
  ax <- rep(0.5, length(x))
  
  if (x[1] == 0) {
    ax[1] <- ifelse(sex == "m", 
                    ifelse(mx[1] >= 0.107, 0.33, 0.045 + 2.684 * mx[1]),
                    ifelse(mx[1] >= 0.107, 0.35, 0.053 + 2.800 * mx[1]))
  }
  
  if (x[2] == 1) {
    ax[2] <- ifelse(sex == "m",
                    ifelse(mx[1] >= 0.107, 1.352, 1.651 - 2.816 * mx[1]),
                    ifelse(mx[1] >= 0.107, 1.361, 1.522 - 1.518 * mx[1]))
  }
  
  if (!is.na(n[length(n)])) ax[length(ax)] <- 1 / mx[length(mx)]
  
  qx <- n * mx / (1 + (n - ax) * mx)
  qx[length(qx)] <- 1
  
  lx <- numeric(length(x))
  lx[1] <- l0
  for (i in 2:length(lx)) lx[i] <- lx[i - 1] * (1 - qx[i - 1])
  
  dx <- lx * qx
  Lx <- numeric(length(x))
  for (i in 1:(length(Lx) - 1)) Lx[i] <- n[i] * lx[i + 1] + ax[i] * dx[i]
  Lx[length(Lx)] <- lx[length(lx)] * ax[length(ax)]
  
  Tx <- rev(cumsum(rev(Lx)))
  ex <- Tx / lx
  
  data.frame(x = x, mx = mx, qx = qx, ax = ax, lx = lx, dx = dx, Lx = Lx, Tx = Tx, ex = ex)
}

# Defunciones
def <- fread("data/def_pro.csv")[year %in% c(2009:2011, 2018:2022)]
def[, year_new := fcase(
  year %in% 2009:2011, 2010,
  year %in% 2018:2019, 2019,
  year %in% 2020:2022, 2021
)]
def <- def[, .(deaths = mean(deaths, na.rm = TRUE)), .(year = year_new, sex, age)]
write.csv(def, "data/def.csv", row.names = FALSE)

# Población - cálculo simplificado
censos <- fread("data/censos_pro.csv")
censos_wide <- dcast(censos, age + sex ~ year, value.var = "pop")

# Calcular años persona vividos
censos_wide[, N_2010 := expo(`2010`, `2020`, "2010-03-15", "2020-03-15", 2010.5)]
censos_wide[, N_2019 := expo(`2010`, `2020`, "2010-03-15", "2020-03-15", 2019.5)]
censos_wide[, N_2021 := `2020` * 1.01]  # Proyección simple

apv <- rbind(
  censos_wide[, .(age, sex, N = N_2010, year = 2010)],
  censos_wide[, .(age, sex, N = N_2019, year = 2019)],
  censos_wide[, .(age, sex, N = N_2021, year = 2021)]
)
write.csv(apv, "data/apv.csv", row.names = FALSE)

# Análisis principal ----
def <- fread("data/def.csv")
apv <- fread("data/apv.csv")

lt_input <- merge(apv, def, by = c("year", "sex", "age"), all.x = TRUE)
lt_input[, mx := deaths/N]

# Asegurar que la codificación de sexo sea consistente
lt_input[, sex := fifelse(sex == "male", "m", 
                          fifelse(sex == "female", "f", sex))]

lt_input <- lt_input[!is.na(mx) & is.finite(mx) & mx > 0]

# Tablas de mortalidad 
lt_output <- data.table()
for(s in c('m', 'f')) {
  for(y in c(2010, 2019, 2021)) {
    temp_dt <- lt_input[sex == s & year == y][order(age)]
    if(nrow(temp_dt) > 0) {
      cat(sprintf("Calculando tabla de vida para %s, año=%d\n", 
                  ifelse(s == "m", "hombres", "mujeres"), y))
      temp_lt <- lt_abr(x = temp_dt$age, mx = temp_dt$mx, sex = s)
      temp_lt$year <- y
      temp_lt$sex <- s
      lt_output <- rbind(lt_output, temp_lt, fill = TRUE)
    }
  }
}

# Renombrar columna x a age para evitar errores
if("x" %in% names(lt_output)) {
  setnames(lt_output, "x", "age")
}

# GRÁFICA 1: Tasa de mortalidad por año y sexo
ggplot(lt_input, aes(x = age, y = mx, color = sex, group = interaction(sex, year))) +
  geom_line(linewidth = 0.8, alpha = 0.8) +
  facet_wrap(~ year, nrow = 1) +
  scale_color_manual(values = c("m" = "steelblue", "f" = "lightcoral"),
                     labels = c("m" = "Hombres", "f" = "Mujeres"),
                     name = "Sexo") +
  scale_y_log10(labels = scales::scientific) +
  labs(title = "Tasa de Mortalidad por Año y Sexo - Guanajuato",
       x = "Edad", 
       y = "Tasa de mortalidad (mx) - escala logarítmica") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))

# GRÁFICA 2: Evolución de la tasa de mortalidad por edad
ggplot(lt_input, aes(x = age, y = mx, color = factor(year), linetype = sex)) +
  geom_line(linewidth = 0.8, alpha = 0.8) +
  scale_color_manual(values = c("2010" = "#1f77b4", "2019" = "#ff7f0e", "2021" = "#2ca02c"),
                     name = "Año") +
  scale_linetype_manual(values = c("m" = "solid", "f" = "dashed"),
                        labels = c("m" = "Hombres", "f" = "Mujeres"),
                        name = "Sexo") +
  scale_y_log10(labels = scales::scientific) +
  labs(title = "Evolución de la Tasa de Mortalidad por Edad - Guanajuato",
       subtitle = "Comparación 2010, 2019 y 2021",
       x = "Edad", 
       y = "Tasa de mortalidad (mx) - escala logarítmica") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

# GRÁFICA 3: Evolución de la mortalidad infantil
mortalidad_infantil <- lt_output[age == 0, .(year, sex, qx)]

ggplot(mortalidad_infantil, aes(x = year, y = qx, color = sex, group = sex)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("m" = "steelblue", "f" = "lightcoral"),
                     labels = c("m" = "Hombres", "f" = "Mujeres"),
                     name = "Sexo") +
  labs(title = "Evolución de la Mortalidad Infantil - Guanajuato",
       subtitle = "Probabilidad de muerte en el primer año de vida (qx a edad 0)",
       x = "Año", 
       y = "Probabilidad de muerte") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

# GRÁFICA 4: Evolución de la esperanza de vida
esperanza_vida <- lt_output[age == 0, .(year, sex, ex)]

ggplot(esperanza_vida, aes(x = year, y = ex, color = sex, group = sex)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  scale_color_manual(values = c("m" = "steelblue", "f" = "lightcoral"),
                     labels = c("m" = "Hombres", "f" = "Mujeres"),
                     name = "Sexo") +
  labs(title = "Evolución de la Esperanza de Vida al Nacer - Guanajuato",
       x = "Año", 
       y = "Años de vida esperados") +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))

# Calcular diferencias entre años
dif_ex <- dcast(esperanza_vida, sex ~ year, value.var = "ex")
dif_ex[, diferencia := `2021` - `2010`]

dif_qx <- dcast(mortalidad_infantil, sex ~ year, value.var = "qx")
dif_qx[, diferencia := `2021` - `2010`]

# Guardar resultados completos
write.csv(lt_output, "data/tabla_mortalidad_guanajuato_2010_2019_2021.csv", row.names = FALSE)

#------------------------------FIN---------------------------------------

