#****************************************************************************#
#************************************************************************************************#
#
#                          Trabajo final del curso de Demografía 2026-1
#                         Facultad de Ciencias UNAM
#                             Tabla de Mortalidad 2010, 2020
#
#         Creado por:               Arwen Yetzirah Ortiz N. y
#                                   Carlos Evnagelista C.
#         Fecha de creación:        04/11/2025
#         Actualizado por:          Arwen Yetzirah Ortiz N. y
#                                   Carlos Evnagelista C.
#         Fecha de actualización:   06/11/2025
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

setwd("C:/Users/arwen/Downloads/Demog_Final_Proj/censos")

## Carga de tablas de datos---
# Preprocesamiento censo 2010

c2010 <- read_xlsx("INEGI_censo2010.xlsx", sheet = 1, 
                   range = "A7:D31")

names(c2010) <- c("age", "tot", "male", "female")
setDT(c2010)

c2010 <- c2010[-1 , ] 

c2010[ , age := gsub("De ", "", age)]
c2010[ , age := substr(age, 1, 2)]
c2010[age=="No", age:=NA]
c2010[ , age:=as.numeric(age)]

c2010[ , tot := as.numeric(gsub(",", "", tot))]
c2010[ , male := as.numeric(gsub(",", "", male))]
c2010[ , female := as.numeric(gsub(",", "", female))]

# Agrupar edades 1-4
c2010[ , age := ifelse(age %in% 1:4, 1, age)]
c2010 <- c2010[ , .(tot = sum(tot), 
                    male = sum(male), 
                    female = sum(female)), by = .(age)]

c2010 <- melt.data.table(c2010, 
                         id.vars = "age",
                         measure.vars = c("male", "female"),
                         variable.name = "sex",
                         value.name = "pop")

sum(c2010$pop)
c2010[ , year:=2010]

# Mostrar tabla 2010
print("Tabla censo 2010:")
c2010

# Preprocesamiento censo 2020

c2020 <- read_xlsx("INEGI_censo2020.xlsx", sheet = 1, 
                   range = "A7:D31")

names(c2020) <- c("age", "tot", "male", "female")
setDT(c2020)

c2020 <- c2020[-1 , ] 

c2020[ , age := gsub("De ", "", age)]
c2020[ , age := substr(age, 1, 2)]
c2020[age=="No", age:=NA]
c2020[ , age:=as.numeric(age)]

c2020[ , tot := as.numeric(gsub(",", "", tot))]
c2020[ , male := as.numeric(gsub(",", "", male))]
c2020[ , female := as.numeric(gsub(",", "", female))]

# Agrupar edades 1-4
c2020[ , age := ifelse(age %in% 1:4, 1, age)]
c2020 <- c2020[ , .(tot = sum(tot), 
                    male = sum(male), 
                    female = sum(female)), by = .(age)]

c2020 <- melt.data.table(c2020, 
                         id.vars = "age",
                         measure.vars = c("male", "female"),
                         variable.name = "sex",
                         value.name = "pop")

sum(c2020$pop)
c2020[ , year:=2020]

# Mostrar tabla 2020
print("Tabla censo 2020:")
c2020

# Unir los dos censos
censos <- rbind(c2010, c2020)

# Mostrar tabla unida
print("Tabla censos unida (2010 y 2020):")
censos

# Prorrateo de los valores perdidos 

censos_pro <- censos[ !is.na(age) ] %>% 
  .[ , p_pop := pop / sum(pop), .(year, sex)] %>% 
  merge( censos[ is.na(age), 
                 .(sex, year, na_pop=pop)], 
         by = c("sex", "year")) %>% 
  .[ , pop_adj := pop + na_pop * p_pop] %>% 
  .[ , .(year, sex, age, pop = pop_adj) ]

# Mostrar tabla después del prorrateo
print("Tabla después del prorrateo:")
censos_pro

# Verificar resultados
print("Población después del prorrateo:")
censos_pro[ , sum(pop), .(year, sex)]

print("Población original:")
censos[ , sum(pop), .(year, sex)]

# Comprobacion de prorrateo
print("Comprobación de prorrateo:")
censos_pro[ , sum(pop), .(year, sex)]
censos[ , sum(pop), .(year, sex)]

#Guardar tabla de censos 
# Crear directorio si no existe
if(!dir.exists("data")) {
  dir.create("data")
}
write.csv(censos_pro, "data/censos_pro.csv", row.names = FALSE)

#-------------------------------FIN--------------------------------------

