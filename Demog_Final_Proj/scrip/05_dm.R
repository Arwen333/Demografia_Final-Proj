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
#         Fecha de actualización:   23/11/2025
#         Contacto:                 arwenort@ciencias.unam.mx
#                                   carlosevangelista@ciencias.unam.mx
#************************************************************************************************#
#************************************************************************************************#
## Limpieza de gráficas----
graphics.off()

## Limpieza de memoria
rm(list=ls())

##Carga paquetes
library(readxl)
library(data.table)
library(dplyr)
library(ggplot2)

# PROCESAMIENTO CORREGIDO DE INEGI_defH.xlsx ----
defH <- read_xlsx("data/INEGI_defH.xlsx", sheet = 1, range = "A6:G20560")
names(defH) <- c("age_group", "tipo", "year", "tot", "male", "female", "ns")
setDT(defH)

# Filtro - eliminar filas totales y no especificadas
defH <- defH[age_group != "Total" & age_group != "No especificado" & 
               tipo == "Total" & year >= 1990]

# Limpieza de grupos de edad - convertir a edades simples
defH[ , age := case_when(
  age_group == "Menores de 1 año" ~ 0,
  age_group == "1-4 años" ~ 1,
  age_group == "5-9 años" ~ 5,
  age_group == "10-14 años" ~ 10,
  age_group == "15-19 años" ~ 15,
  age_group == "20-24 años" ~ 20,
  age_group == "25-29 años" ~ 25,
  age_group == "30-34 años" ~ 30,
  age_group == "35-39 años" ~ 35,
  age_group == "40-44 años" ~ 40,
  age_group == "45-49 años" ~ 45,
  age_group == "50-54 años" ~ 50,
  age_group == "55-59 años" ~ 55,
  age_group == "60-64 años" ~ 60,
  age_group == "65-69 años" ~ 65,
  age_group == "70-74 años" ~ 70,
  age_group == "75-79 años" ~ 75,
  age_group == "80-84 años" ~ 80,
  age_group == "85 años y más" ~ 85,
  TRUE ~ NA_real_
)]

# Limpieza de valores numéricos
defH[ , tot := as.numeric(gsub(",", "", tot))]
defH[ , male := as.numeric(gsub(",", "", male))]
defH[ , female := as.numeric(gsub(",", "", female))]
defH[ , ns := as.numeric(gsub(",", "", ns))]

# Eliminar filas con edad NA
defH <- defH[!is.na(age)]

# Prorrateo de valores perdidos ----
## Por sexo ----
def_proH <- defH[ , .(male = sum(male, na.rm = TRUE), 
                      female = sum(female, na.rm = TRUE),
                      ns = sum(ns, na.rm = TRUE)), 
                  .(year, age)]

# Prorratear los no especificados entre hombres y mujeres
def_proH[ , tot := male + female]
def_proH[ , p_male := male / tot]
def_proH[ , p_female := female / tot]
def_proH[ , male_adj := male + p_male * ns]
def_proH[ , female_adj := female + p_female * ns]
def_proH <- def_proH[ , .(year, age, male = male_adj, female = female_adj)]

# Formato long
def_proH <- melt.data.table(def_proH, 
                            id.vars = c("year", "age"),
                            measure.vars = c("male", "female"),
                            variable.name = "sex",
                            value.name = "deaths")

# CÁLCULO DE TABLAS DE DECREMENTO MÚLTIPLE ----

# 1. Preparar datos para años de referencia ----
def_proH[ , year_new := case_when(
  year %in% 2009:2011 ~ 2010,
  year %in% 2018:2019 ~ 2019,
  year %in% 2020:2022 ~ 2021,  
  TRUE ~ as.numeric(year)
)]

def_base <- def_proH[ , .(deaths = mean(deaths)), .(year = year_new, sex, age)]

# 2. USAR POBLACIÓN CONSTANTE para calcular tasas ----
def_base[ , population := 100000]  # Para calcular tasas mx

# 3. CALCULAR TASAS DE MORTALIDAD ----
def_base[ , mx := deaths / population]

# 4. FUNCIÓN CORREGIDA PARA TABLAS DE VIDA ----
calcular_tabla_vida <- function(data) {
  # Limpiar y ordenar datos
  data_clean <- data[!is.na(age) & !is.na(mx) & is.finite(mx)]
  data_clean <- data_clean[order(year, sex, age)]
  
  if(nrow(data_clean) == 0) {
    return(data.table())
  }
  
  # Para cada grupo (año, sexo), calcular tabla de vida
  resultados <- data_clean[ , {
    # Ordenar por edad
    grupo <- .SD[order(age)]
    
    # Calcular probabilidad de muerte
    grupo[ , qx := 1 - exp(-mx)]
    
    # INICIALIZAR lx SOLO PARA LA EDAD MÍNIMA = 100,000
    edad_min <- min(grupo$age)
    grupo[age == edad_min, lx := 100000]
    
    # Calcular lx iterativamente para las demás edades
    if(nrow(grupo) > 1) {
      edades_ordenadas <- sort(grupo$age)
      
      for(i in 2:length(edades_ordenadas)) {
        edad_actual <- edades_ordenadas[i]
        edad_anterior <- edades_ordenadas[i-1]
        
        lx_anterior <- grupo[age == edad_anterior, lx]
        qx_anterior <- grupo[age == edad_anterior, qx]
        
        if(length(lx_anterior) > 0 && length(qx_anterior) > 0) {
          lx_actual <- lx_anterior * (1 - qx_anterior)
          grupo[age == edad_actual, lx := lx_actual]
        }
      }
    }
    
    # Calcular demás funciones de la tabla de vida
    grupo[ , dx := lx * qx]
    grupo[ , Lx := lx - dx/2]
    grupo[ , Tx := rev(cumsum(rev(Lx)))]
    grupo[ , ex := Tx / lx]
    
    grupo
  }, by = .(year, sex)]
  
  return(resultados)
}

# 5. CALCULAR TABLA DE VIDA ----
decremento_observado <- calcular_tabla_vida(def_base)

print("Tabla de vida calculada - primeras filas:")
print(head(decremento_observado))

# 6. RESULTADOS PRINCIPALES ----
if(nrow(decremento_observado) > 0) {
  # Esperanza de vida al nacer (edad 0)
  esperanza_vida <- decremento_observado[age == 0, .(ex_0 = ex), .(sex, year)]
  
  # GRÁFICAS ----
  
  # 1. Esperanza de vida por sexo 
  ggplot(esperanza_vida, aes(x = year, y = ex_0, color = sex)) +
    geom_line(linewidth = 1.5) +
    geom_point(size = 4) +
    scale_color_manual(
      values = c("male" = "#2E5A87", "female" = "#A64D79"),
      labels = c("male" = "Hombres", "female" = "Mujeres"),
      name = NULL
    ) +
    scale_x_continuous(
      breaks = c(2010, 2019, 2021),
      labels = c("2010", "2019", "2021"),
      limits = c(2009, 2022)  # Extender los límites para dar espacio
    ) +
    labs(
      title = "Esperanza de Vida por Homicidios al Nacer",
      subtitle = "Guanajuato, 2010-2021",
      x = NULL, 
      y = "Años de esperanza de vida",
      caption = "Fuente: Elaboración propia con datos de INEGI"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16, hjust = 0.5, margin = margin(b = 8)),
      plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40", margin = margin(b = 15)),
      plot.caption = element_text(size = 10, color = "gray50", hjust = 1),
      axis.title.y = element_text(face = "bold", margin = margin(r = 10)),
      axis.text = element_text(size = 12),
      axis.text.x = element_text(face = "bold", size = 12, margin = margin(t = 5)),
      legend.position = "top",
      legend.text = element_text(size = 12),
      legend.margin = margin(b = 8),
      panel.grid.major = element_line(color = "grey90"),
      panel.grid.minor = element_blank(),
      plot.margin = margin(15, 15, 15, 15)
    )
  # 2. Curvas de supervivencia (lx) - 2021
  ggplot(decremento_observado[year == 2021], 
         aes(x = age, y = lx, color = sex)) +
    geom_line(linewidth = 1) +
    labs(title = "Curvas de Supervivencia por Homicidios (2021)",
         subtitle = "Guanajuato - lx comienza en 100,000 a edad 0",
         x = "Edad", y = "lx (Sobrevivientes)") +
    scale_color_manual(values = c("male" = "blue", "female" = "red")) +
    theme_minimal()
  
  # 3. Probabilidades de muerte (qx) - 2021
  ggplot(decremento_observado[year == 2021], 
         aes(x = age, y = qx, color = sex)) +
    geom_line(linewidth = 1) +
    scale_y_log10() +
    labs(title = "Probabilidades de Muerte por Homicidios (2021)",
         subtitle = "Guanajuato",
         x = "Edad", y = "qx (Probabilidad de muerte, log)") +
    scale_color_manual(values = c("male" = "blue", "female" = "red")) +
    theme_minimal()
  
  # 4. Distribución de defunciones (dx) - 2021
  ggplot(decremento_observado[year == 2021], 
         aes(x = age, y = dx, fill = sex)) +
    geom_col(position = "dodge", alpha = 0.7) +
    labs(title = "Distribución de Defunciones por Homicidios (2021)",
         subtitle = "Guanajuato",
         x = "Edad", y = "dx (Defunciones)") +
    scale_fill_manual(values = c("male" = "blue", "female" = "red")) +
    theme_minimal()
  
  # GUARDAR RESULTADOS ----
  write.csv(decremento_observado, "data/tabla_decremento_homicidios.csv", row.names = FALSE)
  write.csv(esperanza_vida, "data/esperanza_vida_homicidios.csv", row.names = FALSE)
  write.csv(def_proH, "data/def_proH_homicidios.csv", row.names = FALSE)
  
# ANÁLISIS ADICIONAL - COMPARACIÓN ENTRE AÑOS ----
if(nrow(decremento_observado) > 0) {
  # Comparar curvas de supervivencia entre años
  años_comparar <- c(2010, 2019, 2021)
  
  ggplot(decremento_observado[year %in% años_comparar], 
         aes(x = age, y = lx, color = as.factor(year), linetype = sex)) +
    geom_line(linewidth = 1) +
    labs(title = "Evolución de las Curvas de Supervivencia por Homicidios",
         subtitle = "Comparación Guanajuato 2010 vs 2019 vs 2021",
         x = "Edad", y = "lx (Sobrevivientes)", 
         color = "Año", linetype = "Sexo") +
    theme_minimal()
}
#-------------------------------FIN---------------------------------------------
  
  