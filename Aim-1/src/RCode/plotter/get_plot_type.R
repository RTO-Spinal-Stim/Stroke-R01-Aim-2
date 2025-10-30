get_plot_type <- function(plot_type = "bar") {
    # PURPOSE: Get plot type
    # INPUTS:
    #   plot_type: plot type (default = "bar")
    #
    # OUTPUTS:
    #   plot_type: plot type (lowercase)

    supported_plot_types = c("bar", "scatter")
    if (!plot_type %in% supported_plot_types) {
        stop("Invalid plot type. Must be one of: ", paste(supported_plot_types, collapse = ", "))
    }
    return(tolower(plot_type))
}