# frozen_string_literal: true

# Pagy configuration (version 43+)
# Note: Bootstrap extras load via the Loader module; bootstrap_series_nav helpers
# are available without an explicit require.

# Official API: Pagy::OPTIONS (Pagy.options is deprecated and warns at boot)
Pagy::OPTIONS[:limit] = 25 # default items per page
# Nav window uses :slots (Integer). Old :size arrays are ignored in Pagy 43+.
# Default SERIES_SLOTS is 7 — leave unset unless we need a different window.
