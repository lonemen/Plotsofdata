library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(magrittr)
library(ggbeeswarm)



samplemedian <- function (x, d) {
  return(median(x[d]))}

i=0
#Number of bootstrap samples
nsteps=1000

#Confidence level
Confidence_Percentage = 95
Confidence_level = Confidence_Percentage/100

alpha=1-Confidence_level
lower_percentile=(1-Confidence_level)/2
upper_percentile=1-((1-Confidence_level)/2)


#Read a text file (comma separated values)
df_wide <- read.csv("Data_wide.csv", na.strings = "")

ui <- fluidPage(
  titlePanel("ComPlotta - Comparison by Plotting the Data"),
  sidebarLayout(
    sidebarPanel(width=3,
      conditionalPanel(
        condition = "input.tabs=='Plot'",
        sliderInput("alphaInput", "Visibility of the data", 0, 1, 0.3),
        checkboxInput(inputId = "no_jitter",
                      label = "No Jitter (for small n)",
                      value = FALSE),
        selectInput("var_list", "Colour:", choices = ""),
        
        # conditionalPanel(
        #   condition = "input.adjust_jitter == true",
        #   sliderInput("jitter_width", "Width:", 0,0.5,0.3),
        #   checkboxInput(inputId = "random_jitter", label = ("Randomize Jitter"), value = TRUE)
        # ),
          
        radioButtons("summaryInput", "Statistics", choices = list("Median" = "median", "Mean" = "mean", "Boxplot" = "boxplot", "Violin Plot" = "violin"), selected = "median"),
#        sliderInput("Input_CI", "Confidence Level", 90, 100, 95),
#       sliderInput("Input_CI", "Confidence Level", 90, 100, 95),
#        conditionalPanel(condition = "input.add_CI == true", h5("Not recommended for n<10")),
        checkboxInput(inputId = "add_CI", label = HTML("Add 95% CI <br/> (unadvisable for n<10)"), value = FALSE),
        sliderInput("alphaInput_summ", "Visibility of the statistics", 0, 1, 1),

  

        h4("Plot Layout"),      
        numericInput("plot_height", "Height (# pixels): ", value = 480),
        numericInput("plot_width", "Width (# pixels):", value = 480),

        checkboxInput(inputId = "adjust_scale",
              label = "Adjust scaling",
              value = FALSE),
        conditionalPanel(
              condition = "input.adjust_scale == true",
              textInput("range", "Range of values (min,max)", value = "0,2")
              
        ),
        checkboxInput(inputId = "ordered",
                      label = "Order data based on median value",
                      value = FALSE),
        checkboxInput(inputId = "rotate_plot",
              label = "Rotate plot 90 degrees",
              value = FALSE),

        h4("Labels"),

        checkboxInput(inputId = "add_title",
                        label = "Add title",
                        value = FALSE),
        conditionalPanel(
        condition = "input.add_title == true",
        textInput("title", "Title:", value = "")
        ),


        checkboxInput(inputId = "label_axes",
              label = "Change labels",
              value = FALSE),
        conditionalPanel(
              condition = "input.label_axes == true",
              textInput("lab_x", "X-axis:", value = ""),
              textInput("lab_y", "Y-axis:", value = "")
              
        ),


        checkboxInput(inputId = "adj_fnt_sz",
              label = "Change font size",
              value = FALSE)
        ),
        conditionalPanel(
              condition = "input.adj_fnt_sz == true",
              numericInput("fnt_sz_ttl", "Size axis titles:", value = 24),
              numericInput("fnt_sz_ax", "Size axis labels:", value = 18)
 
      ),
      
      conditionalPanel(
        condition = "input.tabs=='Data upload'",
        h4("Data upload"),
        radioButtons(
          "data_input", "",
          choices = 
            list("Load sample data" = 1,
                 "Upload file" = 2,
                 "Paste data" = 3)
          ,
          selected =  3),
        conditionalPanel(
          condition = "input.data_input=='1'"
          
        ),
        conditionalPanel(
          condition = "input.data_input=='2'",
          h5("Upload file: "),
          fileInput("upload", "", multiple = FALSE),
          selectInput("file_type", "Type of file:",
                      list("text (csv)" = "text",
                           "Excel" = "Excel"
                      ),
                      selected = "text"),
          conditionalPanel(
            condition = "input.file_type=='text'",

          radioButtons(
              "upload_delim", "Delimiter",
              choices = 
                list("Comma" = ",",
                     "Tab" = "\t",
                     "Semicolon" = ";",
                     "Space" = " "),
              selected = ",")),
          
          actionButton("submit_datafile_button",
                       "Submit datafile")),
        conditionalPanel(
          condition = "input.data_input=='3'",
          h5("Paste data below:"),
          tags$textarea(id = "data_paste",
                        placeholder = "Add data here",
                        rows = 10,
                        cols = 20, ""),
          actionButton("submit_data_button", "Submit data"),
              radioButtons(
                "text_delim", "Delimiter",
                choices = 
                    list("Tab (from Excel)" = "\t",
                         "Space" = " ",
                         "Comma" = ",",
                         "Semicolon" = ";"),
                          selected = "\t")),
        checkboxInput(inputId = "tidyInput",
                      label = "These data are Tidy",
                      value = FALSE),
        conditionalPanel(
          condition = "input.tidyInput==true",
          h5("",
             a("Click here for more info on tidy data",
               href = "http://thenode.biologists.com/converting-excellent-spreadsheets-tidy-data/education/")),
          selectInput("y_var", "Variables:", choices = "")
          
          )
      ),
      
      # conditionalPanel(
      #   condition = "input.tabs=='About'",
      #   h4("About")    
      # ),
      
      conditionalPanel(
        condition = "input.tabs=='Data Summary'",
        h4("Data summary")    
      )
      
      
      
    ),
    mainPanel(
 
       tabsetPanel(id="tabs",
                  tabPanel("Data upload", h4("Data as provided"), dataTableOutput("data_uploaded")),
                  tabPanel("Plot", downloadButton("downloadPlotPDF", "Download pdf-file"), plotOutput("coolplot")
                  ), 
                  tabPanel("Data Summary", tableOutput('data_summary')),
                  tabPanel("About", includeHTML("about.html")
                           )
                  
      )
    )
  )         
)

server <- function(input, output, session) {

  
  #####################################
  ###### DATA INPUT ####### ###########
  #####################################
  
  ######
  ### Need to implement the conversion of a tidy-data set to dataframe that can be used for plotting
  ### Ithink I will need select and the input of a string
  #df_tidy_ITSN %>% select (Condition=ratio, Value = Value)
  #df_tidy_ITSN %>% select(Condition= !!var1, Value = !!var2)
  
  df_upload <- reactive({
    if (input$data_input == 1) {
      data <- df_wide
    } else if (input$data_input == 2) {
      file_in <- input$upload
      # Avoid error message while file is not uploaded yet
      if (is.null(input$upload)) {
        return(data.frame(x = "Select your datafile"))
      } else if (input$submit_datafile_button == 0) {
        return(data.frame(x = "Press 'submit datafile' button"))
      } else {
        isolate({
          if (input$file_type == "text") {
            data <- read_delim(file_in$datapath,
                               delim = input$upload_delim,
                               col_names = TRUE)
          } else if (input$file_type == "Excel") {
            data <- read_excel(file_in$datapath)
          } 
        })
      }
    } else if (input$data_input == 3) {
      if (input$data_paste == "") {
        data <- data.frame(x = "Copy your data into the textbox,
                           select the appropriate delimiter, and
                           press 'Submit data'")
      } else {
        if (input$submit_data_button == 0) {
          return(data.frame(x = "Press 'submit data' button"))
        } else {
          isolate({
            data <- read_delim(input$data_paste,
                               delim = input$text_delim,
                               col_names = TRUE)
          })
        }
      }
  }
    return(data)
})
  
#Need to tidy the data?!
  df_tidy_temp <- reactive({
    if(input$tidyInput == FALSE ) {
      klaas <- gather(df_upload(), Condition, Value)
    }
    else if(input$tidyInput == TRUE ) {
      klaas <- df_upload()
 #     klaas <- df_upload() %>% mutate (Value = input$var)
      ##### Change column name that is selected by input$var to "Value"
      
    }
    })
  

#################### GET a List of variables that can be used for colour ################
observe({ 
        var_names  <- names(df_tidy_temp())
        var_list <- c("none", var_names)
        updateSelectInput(session, "var_list", choices = var_list)
        updateSelectInput(session, "y_var", choices = var_list)
})
  
  
  df_tidy <- reactive({
    klaas <- df_tidy_temp() 
#    y_choice <- as.character(input$y_var)
 #   observe({ print(y_choice)})
  #    koos <- klaas %>% mutate_(Value, y_choice)
   # observe({ print(head(koos)) })
  #  return(koos)
})
  
  
  
###########################################
#### DISPLAY UPLOADED DATA ####
###########################################
    
output$data_uploaded <- renderDataTable({
    
#    observe({ print(input$tidyInput) })
      df_upload()
  })
  

###########################################
#### DISPLAY Summary of the DATA ####
###########################################

output$data_summary <- renderTable({
#    df_summary()
    df_out <- NULL
    if (input$summaryInput == "mean") {
    df_out <- df_summary()
    df_out$median <- NULL
    } else if (input$summaryInput == "median") {
    df_out <- df_booted_summary()
    } 
    return(df_out)
})


###########################################
#### Caluclate Summary of the DATA for the MEAN ####
###########################################


df_summary <- reactive({
  kees <- df_tidy() %>%
    filter(!is.na(Value))
    if(input$ordered == TRUE) {
      koosje <- kees %>% mutate(Condition = reorder(Condition, Value, median))
    } else if (input$ordered == FALSE) {koosje <- kees}
    
 #   observe({ print(koosje$Value) })
  
    koosje %>%
    group_by(Condition) %>% 
    summarise(n = n(),
            mean = mean(Value, na.rm = TRUE),
            median = median(Value, na.rm = TRUE),
            sd = sd(Value, na.rm = TRUE)) %>%
  mutate(sem = sd / sqrt(n - 1),
         ci_lo = mean + qt((1-Confidence_level)/2, n - 1) * sem,
         ci_hi = mean - qt((1-Confidence_level)/2, n - 1) * sem)
  
  })  
  
###########################################
#### Caluclate Summary of the DATA for the Median ####
###########################################  


df_booted_summary <- reactive({
    kees <- df_tidy() %>%
      filter(!is.na(Value))
    
    df_booted <- data.frame(Condition=levels(factor(kees$Condition)), n=tapply(kees$Value, kees$Condition, length), median=tapply(kees$Value, kees$Condition, median))
    observe({ print(df_booted) })
    
    i=0
    df_new_medians <- data.frame(Condition=levels(factor(kees$Condition)), resampled_median=tapply(kees$Value, kees$Condition, boot_median), id=i)
    
    #Perform the resampling nsteps number of times (typically 1,000-10,000x)
    for (i in 1:nsteps) {
      
      #Caclulate the median from a boostrapped sample (resampled_median) and add to the dataframe
      df_boostrapped_median <- data.frame(Condition=levels(factor(kees$Condition)), resampled_median=tapply(kees$Value, kees$Condition, boot_median), id=i)
      
      #Add the new median to a datafram that collects all the resampled median values
      df_new_medians <- bind_rows(df_new_medians, df_boostrapped_median)
    }
    df_booted$ci_lo <- tapply(df_new_medians$resampled_median, df_new_medians$Condition, quantile, probs=lower_percentile)
    df_booted$ci_hi <- tapply(df_new_medians$resampled_median, df_new_medians$Condition, quantile, probs=upper_percentile)

    
    if(input$ordered == TRUE) {
      df_booted <- df_booted %>% mutate(Condition = reorder(Condition, median))
    }
    
    return(df_booted)
  })
  
  
###########################################
#### DEFINE DOWNLOAD BUTTON ####
###########################################

output$downloadPlotPDF <- downloadHandler(
  filename <- function() {
    paste("ComparisonPlot_", Sys.time(), ".pdf", sep = "")
  },
  content <- function(file) {
    ggsave(file, width = input$plot_width/72,
           height = input$plot_height/72, dpi="retina")
  },
  contentType = "application/pdf" # MIME type of the image
)

##### Set width and height of the plot area
width <- reactive ({ input$plot_width })
height <- reactive ({ input$plot_height })


###########################################
#### PREPARE PLOT FOR DISPLAY ####
###########################################

output$coolplot <- renderPlot(width = width,
                              height = height,{


    #### Command to prepare the plot ####
    observe({ print(class(input$var_list)) })
                                
    if (input$var_list == "none") {
      kleur <- NULL
    } else if (input$var_list != "none") {
      kleur <- as.character(input$var_list)
    }                          
    p <- ggplot(df_tidy(), aes_string(x="Condition"))
      
    #### plot selected data summary (1st layer) ####
    if (input$summaryInput == "median"  && input$add_CI == TRUE) {
    p <-  p + geom_linerange(data=df_booted_summary(), aes(x=Condition, ymin = ci_lo, ymax = ci_hi), color="black", size =3,alpha=input$alphaInput_summ)+
       geom_point(data=df_summary(), aes(x=Condition, y = median), shape = 21,color = "black",fill=NA,size = 8,alpha=input$alphaInput_summ)

    }

    # if (input$summaryInput == "median"  && input$add_CI == TRUE) {
    #   p <-  p + geom_errorbar(data=df_booted_summary(), aes(x=Condition, ymin = ci_lo, ymax = ci_hi), width=.8, size=2, alpha=input$alphaInput_summ)
    # 
    # }
    
    else if (input$summaryInput == "median"  && input$add_CI == FALSE) {
      p <-  p + geom_errorbar(data=df_summary(), aes(x=Condition, ymin=median, ymax=median), width=.8, size=2, alpha=input$alphaInput_summ)
      
    } else if (input$summaryInput == "mean"  && input$add_CI == TRUE) {
      p <- p + geom_linerange(data=df_summary(), aes(ymin = ci_lo, ymax = ci_hi), color="black", size =3,alpha=input$alphaInput_summ)+
        geom_point(data=df_summary(), aes(y = mean), shape = 21,color = "black",fill=NA,size = 8,alpha=input$alphaInput_summ)

    } else if (input$summaryInput == "mean"  && input$add_CI == FALSE) {
      p <- p + geom_errorbar(data=df_summary(), aes(x=Condition, ymin=mean, ymax=mean), width=.8, size=2, alpha=input$alphaInput_summ)
      
                  
    } else if (input$summaryInput == "boxplot") {
     p <- p + geom_errorbar(data=df_summary(), aes(x=Condition, ymin=median, ymax=median), width=.2, size=2, alpha=0)+
       geom_boxplot(data=df_tidy(), aes(x=Condition, y=Value), fill = "grey50", notch = input$add_CI, outlier.color=NA, width=0.8, size=0.5, alpha=input$alphaInput_summ)
      
    } else if (input$summaryInput == "violin") {
      p <- p + geom_errorbar(data=df_summary(), aes(x=Condition, ymin=median, ymax=median), width=.2, size=2, alpha=0) +
        geom_violin(data=df_tidy(), aes(x=Condition, y=Value), fill = "grey50", width=0.8, size=0.5, alpha=input$alphaInput_summ) 
    }

    
    
    
    # #### plot individual measurements (2nd layer) ####
    # if (input$adjust_jitter == FALSE || input$random_jitter == TRUE) {
    #   #Remove the seed
    #   rm(.Random.seed, envir=globalenv())
    # } else if (input$random_jitter == FALSE) {
    #   set.seed(2)
    # }

    if (input$no_jitter == FALSE) {
      p <- p + geom_quasirandom(data=df_tidy(), aes_string(x="Condition", y="Value", colour = kleur), varwidth = TRUE, cex=3, alpha=input$alphaInput)
    } else if (input$no_jitter == TRUE) {
      p <- p + geom_jitter(data=df_tidy(), aes_string(x="Condition", y="Value", colour = kleur), width=0, height=0.0, cex=3, alpha=input$alphaInput)
    }  
        
#    
     p <- p+ theme_light(base_size = 16)
    
    #### If selected, rotate plot 90 degrees CW ####
    if (input$rotate_plot == TRUE) { p <- p + coord_flip()}
    
    if (input$adjust_scale == TRUE) { 
      rng <- as.numeric(strsplit(input$range,",")[[1]])
      p <- p + ylim(rng[1],rng[2])}

    
    # if title specified
    if (input$add_title)
      p <- p + ggtitle(input$title)
    
    # if labels specified
    if (input$label_axes)
      p <- p + labs(x = input$lab_x, y = input$lab_y)
    
    # if font size is adjusted
    if (input$adj_fnt_sz) {
      p <- p + theme(axis.text = element_text(size=input$fnt_sz_ax))
      p <- p + theme(axis.title = element_text(size=input$fnt_sz_ttl))
    }
        ### Output the plot ######
    p
    
  })
}

shinyApp(ui = ui, server = server)