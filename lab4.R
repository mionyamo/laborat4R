# Esly russkie bukvy ne otobrajautsa: File -> Reopen with encoding... UTF-8

# Используйте UTF-8 как кодировку по умолчанию!
# Установить кодировку в RStudio: Tools -> Global Options -> General, 
#  Default text encoding: UTF-8

# Аналитический пакет R: Занятие 4 ---------------------------------------------

# Создание статических картограмм ==============================================


# загрузка пакетов
library('R.utils')               # gunzip() для распаковки архивов 
library('dismo')                 # gmap() для загрузки Google карты
library('raster')                # функции для работы с растровыми картами в R
library('maptools')              # инструменты для создания картограмм
library('sp')                    # функция spplot()
library('RColorBrewer')          # цветовые палитры
require('rgdal')                 # функция readOGR()
require('plyr')                  # функция join()
library('ggplot2')               # функция ggplot()
library('scales')                # функция pretty_breaks()
# Rtools: https://cran.r-project.org/bin/windows/Rtools/
#  при установке с правами администрарора поставить 
#  галочку 'Current Value' для установки PATH
#  инструкции по установке: 
#    https://github.com/stan-dev/rstan/wiki/Install-Rtools-for-Windows
install.packages("gpclib", type = "source")

library('gpclib')
library('mapproj')

gpclibPermit()

# ссылка на файл
ShapeFileURL <-
  "http://biogeo.ucdavis.edu/data/gadm2.8/shp/RUS_adm_shp.zip"

# создаём директорию 'data' и скачиваем
if(!file.exists('./data')) dir.create('./data')
if(!file.exists('./data/RUS_adm_shp.zip')) {
  download.file(ShapeFileURL,
                destfile = './data/RUS_adm_shp.zip')}
# распаковать архив
unzip('./data/RUS_adm_shp.zip', exdir = './data/RUS_adm_shp')
# посмотреть список файлов распакованного архива
dir('./data/RUS_adm_shp')

#DT.import <- read.csv("C:/Users/alenyamo/Documents/f4.csv", as.is = TRUE)

# прочитать данные уровней 0, 1, 2
Regions0 <- readShapePoly("./data/RUS_adm_shp/RUS_adm0.shp")
Regions1 <- readShapePoly("./data/RUS_adm_shp/RUS_adm1.shp")
Regions2 <- readShapePoly("./data/RUS_adm_shp/RUS_adm2.shp")
Regions3 <- readShapePoly("./data/RUS_adm_shp/RUS_adm3.shp")
# контурные карты для разных уровней иерархии
par(mfrow = c(1, 1))
#plot(Regions0, main = 'adm0', asp = 1.8)
#plot(Regions1, main = 'adm1', asp = 1.8)
plot(Regions2, main = 'adm2', asp = 1.8)
#plot(Regions3, main = 'adm3', asp = 1.8)
# Рис. 5
par(mfrow = c(1, 1))


# имена слотов
slotNames(Regions0)

# слот "данные"
Regions0@data

# делаем фактор из имён областей (т.е. нумеруем их)
Regions3@data$NAME_1 <- as.factor(Regions3@data$NAME_1)
# результат
Regions3@data$NAME_1

stat.Regions <- read.csv('F:/r/f4.csv', # ссылка
                         sep = ';', dec = ',', # разделители
                         as.is = T) # не переводить строки
# в факторы
# читаем ShapeFile из папки, с указанием уровня иерархии
Regions <- readOGR(dsn = './data/RUS_adm_shp', # папка
                   layer = 'RUS_adm3') # уровень
# создаём столбец-ключ id для связи с другими таблицами
# (названия регионов из столбца NAME_1)
Regions@data$id <- Regions3@data$NAME_1
# преобразовываем SpatialPolygonsDataFrame в data.frame
Regions.points <- fortify(Regions, region = 'id')
# добавляем к координатам сведения о регионах
Regions.df <- join(Regions.points, Regions@data, by = 'id')
# добавляем к координатам значения показателя для заливки
# (численность населения из фрейма stat.Regions)
stat.Regions$id <- stat.Regions$Region
Regions.df <- join(Regions.df,
                   stat.Regions[, c('id',
                                    'Air.Polution')],
                   by = 'id')
# имена столбцов фрейма (выделены нужные для графика)
names(Regions.df)
Regions.df$id
# координаты центров полигонов (для подписей регионов)
centroids.df <- as.data.frame(coordinates(Regions))
# названия регионов (идут в том же порядке, в каком
# считались центроиды
centroids.df$id <- Regions@data$id
# заменяем имена переменных, созданные по умолчанию
colnames(centroids.df) <- c('long', 'lat', 'id')

# создаём график
gp <- ggplot() +
  geom_polygon(data = Regions.df,
               aes(long, lat, group = group,
                   fill = Population.people)) +
  geom_path(data = Regions.df,
            aes(long, lat, group = group),
            color = 'coral4') +
  coord_map(projection = 'gilbert') +
  scale_fill_distiller(palette = 'OrRd',
                       direction = 1,
                       breaks = pretty_breaks(n = 5)) +
  labs(x = 'Долгота', y = 'Широта',
       title = "Загрязненность воздуха, куб.метров") +
  geom_text(data = centroids.df,
            aes(long, lat, label = id))
# выводим график
gp 