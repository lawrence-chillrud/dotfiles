# ============================================================================
# ~/.Rprofile  —  user-level R startup (works alongside renv)
# ----------------------------------------------------------------------------
# renv writes its OWN .Rprofile inside each PROJECT (calling renv::activate()).
# This USER-level file sets global defaults that apply everywhere and do not
# interfere with renv's project isolation.
# ============================================================================

local({
  # --- CRAN mirror: fast, reliable default --------------------------------
  r <- getOption("repos")
  r["CRAN"] <- "https://cloud.r-project.org"
  options(repos = r)

  # --- Parallel package compilation: use all cores ------------------------
  options(Ncpus = max(1L, parallel::detectCores()))

  # --- Sensible interactive defaults --------------------------------------
  options(
    warn = 1,                 # show warnings as they occur, not at the end
    max.print = 1000,         # don't flood the console with giant objects
    scipen = 10,              # prefer fixed over scientific notation
    digits = 7,
    stringsAsFactors = FALSE, # explicit > implicit (harmless on R >= 4.0)
    useFancyQuotes = FALSE,
    browserNLdisabled = TRUE,
    timeout = 300             # don't hang forever on slow package downloads
  )

  # --- HPC tip: Linux binary packages via Posit Public Package Manager -----
  # Installing R packages from source on a cluster is painfully slow. P3M
  # serves prebuilt Linux binaries. Uncomment and set your distro codename
  # (find it with: lsb_release -cs). Example for Ubuntu 22.04 "jammy":
  # if (Sys.info()[["sysname"]] == "Linux") {
  #   options(repos = c(P3M = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"))
  #   options(HTTPUserAgent = sprintf(
  #     "R/%s R (%s)", getRversion(),
  #     paste(getRversion(), R.version["platform"], R.version["arch"], R.version["os"])
  #   ))
  # }
})

# --- Friendly interactive-only startup banner ------------------------------
if (interactive()) {
  # Show a hint that renv is active when you're inside a renv project.
  if (file.exists("renv/activate.R")) {
    message("renv project detected — library is project-local.")
  }
  # Pretty tracebacks/errors if installed (optional, never required).
  if (requireNamespace("rlang", quietly = TRUE)) {
    options(error = rlang::entrace)
  }
}

# --- .First / .Last hooks ---------------------------------------------------
.First <- function() {
  if (interactive()) {
    cat(sprintf("R %s — %s\n", getRversion(), R.version$nickname))
  }
}
.Last <- function() {
  if (interactive()) try(cat("Bye.\n"), silent = TRUE)
}
