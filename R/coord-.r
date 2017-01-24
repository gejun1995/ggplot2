#' @section Coordinate systems:
#'
#' All \code{coord_*} functions (like \code{coord_trans}) return a \code{Coord*}
#' object (like \code{CoordTrans}). The \code{Coord*} object is responsible for
#' adjusting the position of overlapping geoms.
#'
#' The way that the \code{coord_*} functions work is slightly different from the
#' \code{geom_*} and \code{stat_*} functions, because a \code{coord_*} function
#' actually "instantiates" the \code{Coord*} object by creating a descendant,
#' and returns that.
#'
#' Each of the \code{Coord*} objects is a \code{\link{ggproto}} object,
#' descended from the top-level \code{Coord}.  To create a new type of Coord
#' object, you typically will want to implement one or more of the following:
#'
#' \itemize{
#'   \item \code{aspect}: Returns the desired aspect ratio for the plot.
#'   \item \code{labels}: Returns a list containing labels for x and y.
#'   \item \code{render_fg}: Renders foreground elements.
#'   \item \code{render_bg}: Renders background elements.
#'   \item \code{render_axis_h}: Renders the horizontal axes.
#'   \item \code{render_axis_v}: Renders the vertical axes.
#'   \item \code{range}: Returns the x and y ranges
#'   \item \code{train}: Return the trained scale ranges.
#'   \item \code{transform}: Transforms x and y coordinates.
#'   \item \code{distance}: Calculates distance.
#'   \item \code{is_linear}: Returns \code{TRUE} if the coordinate system is
#'     linear; \code{FALSE} otherwise.
#'
#'   \item \code{setup_layout}: Allows the coordinate system to manipulate
#'     the \code{panel_layout} data frame which assigns data to panels and
#'     scales.
#' }
#'
#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
Coord <- ggproto("Coord",

  aspect = function(ranges) NULL,

  labels = function(scale_details) scale_details,

  render_fg = function(scale_details, theme) element_render(theme, "panel.border"),

  render_bg = function(scale_details, theme) {
    x.major <- if (length(scale_details$x.major) > 0) unit(scale_details$x.major, "native")
    x.minor <- if (length(scale_details$x.minor) > 0) unit(scale_details$x.minor, "native")
    y.major <- if (length(scale_details$y.major) > 0) unit(scale_details$y.major, "native")
    y.minor <- if (length(scale_details$y.minor) > 0) unit(scale_details$y.minor, "native")

    guide_grid(theme, x.minor, x.major, y.minor, y.major)
  },

  render_axis_h = function(scale_details, theme) {
    arrange <- scale_details$x.arrange %||% c("secondary", "primary")

    list(
      top = render_axis(scale_details, arrange[1], "x", "top", theme),
      bottom = render_axis(scale_details, arrange[2], "x", "bottom", theme)
    )
  },

  render_axis_v = function(scale_details, theme) {
    arrange <- scale_details$y.arrange %||% c("primary", "secondary")

    list(
      left = render_axis(scale_details, arrange[1], "y", "left", theme),
      right = render_axis(scale_details, arrange[2], "y", "right", theme)
    )
  },

  range = function(scale_details) {
    return(list(x = scale_details$x.range, y = scale_details$y.range))
  },

  train = function(scale_details) NULL,

  transform = function(data, range) NULL,

  distance = function(x, y, scale_details) NULL,

  is_linear = function() FALSE,

  setup_layout = function(panel_layout, params) {
    panel_layout
  }
)

#' Is this object a coordinate system?
#'
#' @export is.Coord
#' @keywords internal
is.Coord <- function(x) inherits(x, "Coord")

expand_default <- function(scale, discrete = c(0, 0.6), continuous = c(0.05, 0)) {
  scale$expand %|W|% if (scale$is_discrete()) discrete else continuous
}

# Renders an axis with the correct orientation or zeroGrob if no axis should be
# generated
render_axis <- function(scale_details, axis, scale, position, theme) {
  if (axis == "primary") {
    guide_axis(scale_details[[paste0(scale, ".major")]], scale_details[[paste0(scale, ".labels")]], position, theme)
  } else if (axis == "secondary" && !is.null(scale_details[[paste0(scale, ".sec.major")]])) {
    guide_axis(scale_details[[paste0(scale, ".sec.major")]], scale_details[[paste0(scale, ".sec.labels")]], position, theme)
  } else {
    zeroGrob()
  }
}
