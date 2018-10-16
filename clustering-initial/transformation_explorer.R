library(shiny)
library(shinyjs)
library(magrittr)
library(kableExtra)

wiki_features <- readr::read_csv("data/features.csv")
data_dictionary <- readr::read_csv("data/dictionary.csv")
feature_types <- purrr::map_chr(wiki_features[, -1], typeof)
non_features <- grepl("(name|code)$", names(feature_types))
feature_types <- feature_types[!non_features]
n_features <- length(feature_types)
feature_names <- names(feature_types)
transformations <- as.list(character(n_features))
names(transformations) <- feature_names

ui <- fluidPage(
    titlePanel("Wikimedia Project Segmentation Dimensions"),
    sidebarLayout(
        sidebarPanel(
            useShinyjs(), # Set up shinyjs
            disabled(actionButton("prev_feat", "Previous", icon = icon("arrow-left"), display = "inline")),
            actionButton("next_feat", "Next", icon = icon("arrow-right"), display = "inline"),
            br(),
            radioButtons("transformation", "Transformation", choices = c("none", "log10", "sqrt")),
            actionButton("remember_transformation", "Remember transformation", icon = icon("save")),
            br(),
            checkboxInput("standardize", "Standardize"),
            br(),
            actionButton("finish", "Finish", icon = icon("check"))
        ),
        mainPanel(
            textOutput("feature_name"),
            uiOutput("summary"),
            textOutput("feature_description")
        )
    ),
    theme = shinythemes::shinytheme("cosmo")
)

server <- function(input, output, session) {
    transformations_memory <- transformations
    current_feature <- reactiveVal(1)
    observeEvent(input$prev_feat, isolate({
        new_value <- current_feature() - 1
        toggleState("next_feat", new_value < n_features)
        toggleState("prev_feat", new_value > 1)
        current_feature(new_value)
    }))
    observeEvent(input$next_feat, isolate({
        new_value <- current_feature() + 1
        toggleState("next_feat", new_value < n_features)
        toggleState("prev_feat", new_value > 1)
        current_feature(new_value)
    }))
    observeEvent(input$remember_transformation, isolate({
        selected_feature <- feature_names[current_feature()]
        transformation_to_remember <- input$transformation
        transformations_memory[[selected_feature]] <<- transformation_to_remember
    }))
    observeEvent(input$finish, {
        stopApp(transformations_memory)
    })
    observeEvent(current_feature(), isolate({
        selected_feature <- feature_names[current_feature()]
        transformation <- transformations_memory[[selected_feature]]
        if (transformation %in% c("", "none")) {
            updateRadioButtons(session, "transformation", selected = "none")
        } else {
            updateRadioButtons(session, "transformation", selected = transformation)
        }
    }))
    output$feature_name <- renderText({
        feature_names[current_feature()]
    })
    output$feature_description <- renderText({
        selected_feature <- feature_names[current_feature()]
        req(selected_feature %in% data_dictionary$metric)
        data_dictionary$definition[data_dictionary$metric == selected_feature]
    })
    output$summary <- renderUI({
        selected_feature <- feature_names[current_feature()]
        if (feature_types[selected_feature] != "character") {
            return(plotOutput("plot_summary"))
        } else {
            return(tableOutput("table_summary"))
        }
    })
    output$plot_summary <- renderPlot({
        selected_feature <- feature_names[current_feature()]
        if (feature_types[selected_feature] != "character") {
            x <- as.numeric(wiki_features[[selected_feature]])
            apply_transformation <- input$transformation
            x <- dplyr::case_when(
                apply_transformation == "none" ~ x,
                apply_transformation == "log10" ~ log10(x + 0.1),
                apply_transformation == "sqrt" ~ sqrt(x)
            )
            if (input$standardize) {
                x <- (x - mean(x)) / sd(x)
            }
            hist(x, xlab = NULL, ylab = NULL, freq = FALSE,
                 main = paste("Distribution of", selected_feature),
                 sub = paste("The following transformation has been applied:", apply_transformation))
        }
    })
    output$table_summary <- renderTable({
        selected_feature <- feature_names[current_feature()]
        if (feature_types[selected_feature] == "character") {
            wiki_features[[selected_feature]] %>%
                factor %>%
                table %>%
                dplyr::as_data_frame() %>%
                set_colnames(c("category", "n")) %>%
                dplyr::mutate(prop = scales::percent(n / sum(n))) %>%
                dplyr::rename(observations = n) %>%
                dplyr::top_n(10, dplyr::desc(observations)) %>%
                dplyr::select(category, prop)
        }
    }, striped = TRUE, bordered = TRUE)
}

app <- shinyApp(ui, server)
remembered_transformations <- runApp(app)

remembered_transformations %>%
    dplyr::as_data_frame() %>%
    tidyr::gather(variable, transformation) %>%
    dplyr::mutate(transformation = dplyr::if_else(transformation == "", "none", transformation)) %>%
    readr::write_csv("data/transformations.csv")

to_transform <- remembered_transformations %>%
    purrr::map_lgl(~ .x == "log10") %>%
    { names(.)[.] }
standardize <- function(x) {
    return((x - mean(x)) / sd(x))
}

for (dimension in to_transform) {
    wiki_features[[dimension]] <- standardize(log10(wiki_features[[dimension]] + 0.1))
}

wiki_features$`script direction` <- as.numeric(wiki_features$`script direction` == "right-to-left")

readr::write_csv(wiki_features[, c(TRUE, !non_features)], "data/refined.csv")
