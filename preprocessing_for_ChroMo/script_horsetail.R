#set the path where your csv files are placed. Example: "C:\\User\\preprocessing_for_ChroMo\\CSV\\CSV_batch\\"
path <- ()
setwd(path)

#input the csv filename obtained from chromo. Example: "AFA123_chromo.csv"
chromo_csv_filename <- ""

#the chosen name for the stop values csv file. Example: AFA123_chromo_stop.csv
stop_data_filename <- ""

#the chose name for the final file with only the horsetail data. Example: AFA123_chromo_horsetail.csv
output_filename <- ""

#We read the csv and define the experimental stop speed

df <- read.csv(paste0(path,chromo_csv_filename))

#this is the velocity value to detect the stop cell movement
speed_stop_threshold <- 0.2992296

#Loop
particle <- NULL
durationHT <- NULL
durationPosHT <- NULL
position <- 1
for (i in unique(df$particle)) {
  cell <- df[df$particle == i,] 
  a <- 0
  j <- 1
  while (sum(a)<6){
    vector <- cell$cal.speed[j:(j+5)]
     if (any(is.na(vector))){
       print(paste0("Particle: ",i, " stop not detected."))
       break
     }
    a <- ifelse(vector<speed_stop_threshold,1,0)
    j <- j+1
  }
  
  durationHT[position] <- j
  durationPosHT[position] <- length(cell$frame)-j
  particle[position] <- i
  position <- position + 1
}
# horsetail values file:
datos <- data.frame(particle,durationHT,durationPosHT)

#Incorrect particle stop processing:
datos$durationHT[datos$durationPosHT== 4] <- datos$durationHT[datos$durationPosHT== 4] + 4
datos$durationPosHT[datos$durationPosHT == 4] <- 0

#Save final data

#stop_data_filename <- "AFA_123_chromo_stop_values.csv"
write.csv(datos, paste0(path,stop_data_filename), row.names = FALSE)

# this is .csv file processed with chromo

df <- read.csv(paste0(path,chromo_csv_filename))

# this is the file generated in the previous step in line 30

df_stop_values <- datos

vector_stop_values <- NULL
for (i in unique(df_stop_values$particle)){
  vector_stop_values <-c(vector_stop_values,df_stop_values$durationPosHT[df_stop_values$particle == i])
  
}

df_subset <- df

all_cells <- NULL
for (i in unique(df_subset$particle)){
  
  all_cells <- c(all_cells,unique(df_subset$particle[df_subset$particle == i]) )
  
}

## this deletes the posthorsetail phase
n <- 0
i <- NULL
out_df <- NULL
out_df <- df_subset

for (i in unique(df$particle)){
  
  n <- n+1
  
  out_df <-out_df[!((out_df$frame > -(vector_stop_values[n])) & out_df$particle == i), ]         
  
}



write.csv(out_df, file = paste0(path,output_filename),row.names = FALSE)
