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
# Preprocesamiento de defunciones 1990-2024----
def <- read_xlsx("data/INEGI_def.xlsx", sheet = 1, 
                 range = "A6:G20560")

names(def) <- c("age", "year", "reg", 
                "tot", "male", "female", "ns")
setDT(def)

# Filtro----
def <- def[age!="Total" & year!="Total" & year>=1990]

def[ , .N, .(age)]

def[ , age := gsub("Menores de ", "", age)]
def[ , age := substr(age, 1, 2)]
def[age=="1 ", age:=0]
def[age=="1-", age:=1]
def[age=="5-", age:=5]
def[age=="No", age:=NA] # prorrateo
def[ , age:=as.numeric(age)]

def[ , tot := as.numeric(gsub(",", "", tot))]
def[ , male := as.numeric(gsub(",", "", male))]
def[ , female := as.numeric(gsub(",", "", female))]
def[ , ns := as.numeric(gsub(",", "", ns))]

# Tabla de defunciones - comprobación 
def_comp <- def[ , .(tot=sum(tot, na.rm = T),
                     male=sum(male, na.rm = T), 
                     female=sum(female, na.rm = T),
                     ns=sum(ns, na.rm = T)), 
                 .(year)]

# Imputación
def[year=="No especificado", year:=reg] 
def[ , year:=as.numeric(year)] 
def_comp[ , sum(tot)]


# Tabla para prorrateo de defunciones 
def_pro <- def[ , .(male=sum(male, na.rm = T), 
                    female=sum(female, na.rm = T),
                    ns=sum(ns, na.rm = T)), 
                .(year, age)]


# Prorrateo de los valores perdidos (missing)----
##sexo----
def_pro[ , tot:=male+female][ , `:=`(p_male=male/tot, p_female=female/tot)]
def_pro[ , `:=`(male_adj=male+p_male*ns, female_adj=female+p_female*ns)]
def_pro <- def_pro[ , .(year, age, male=male_adj, female=female_adj)]
sum(def_pro$male)+sum(def_pro$female)

#Formato long
def_pro <- melt.data.table(def_pro, 
                           id.vars = c("year", "age"),
                           measure.vars = c("male", "female"),
                           variable.name = "sex",
                           value.name = "deaths")
#Extra, formato wide
dcast(def_pro, formula = year+age ~sex)
sum(def_pro$deaths)
def_pro[ , sum(deaths), .(year, sex)]

## Edad----
def_pro <- def_pro[ !is.na(age) ] %>% 
  .[ , p_deaths := deaths / sum(deaths), .(year, sex)] %>% 
  merge( def_pro[ is.na(age), 
                  .(sex, year, na_deaths=deaths)], 
         by = c("sex", "year")) %>% 
  .[ , deaths_adj := deaths + na_deaths * p_deaths] %>% 
  .[ , .(year, sex, age, deaths = deaths_adj) ]

#Gráfica----
def_gr <- def_pro[ , .(deaths=sum(deaths)), .(year, sex)]
library(ggplot2)
ggplot(def_gr, aes(x = year, y = deaths, color = sex, group = sex)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  labs(title = "Evolución de Defunciones por Sexo (1990-2024)",
       x = "Año",
       y = "Número de Defunciones",
       color = "Sexo") +
  scale_color_manual(values = c("male" = "blue", "female" = "red")) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Gráfica adicional: Defunciones por grupos de edad (promedio 2010-2021)
def_edad <- def_pro[year %in% 2010:2021, .(deaths = mean(deaths)), .(age, sex)]

ggplot(def_edad, aes(x = age, y = deaths, fill = sex)) +
  geom_col(position = "dodge") +
  labs(title = "Defunciones Promedio por Edad y Sexo (2010-2021)",
       x = "Edad",
       y = "Defunciones Promedio",
       fill = "Sexo") +
  scale_fill_manual(values = c("male" = "blue", "female" = "red")) +
  theme_minimal()


# Guardar tabla de DEF prorrateadas----
write.csv(def_pro, "data/def_pro.csv", row.names = F)

# Carga de tablas de datos ----
def_pro <- fread("data/def_pro.csv") %>% 
  .[year %in% c(2009, 2010, 2011, 2018, 2019, 2020, 2021, 2022)]  # Incluir años alrededor de 2021


## calculo del promedio para el año de referencia
def_pro[ , year_new := case_when(
  year %in% 2009:2011 ~ 2010,
  year %in% 2018:2019 ~ 2019,
  year %in% 2020:2022 ~ 2021,  
  TRUE ~ as.numeric(year)
)]

# datos preparados de defunciones
def <- 
  def_pro[ , 
           .( deaths = mean( deaths ) ),
           .( year = year_new, sex, age ) ] 

# Guardar tabla de DEF ----
write.csv(def, "data/def.csv", row.names = FALSE)

# -------------------------- FIN -------------------------------------*
