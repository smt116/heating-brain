[
  import_deps: [:stream_data],
  inputs: [
    "*.{ex,exs}",
    "config/*.{ex,exs}",
    "apps/**/config/**/*.{ex,exs}",
    "apps/**/lib/**/*.{ex,exs}",
    "apps/**/test/**/*.{ex,exs}",
    "apps/**/priv/**/*.{ex,exs}",
    "apps/**/mix.exs",
    "mix.exs"
  ],
  subdirectories: ["apps/*"]
]
