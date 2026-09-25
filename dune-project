(lang dune 3.24)
(name discord)
(generate_opam_files true)

(source
  (github gavrh/discordml))

(authors "Gavin Holmes")
(maintainers "Gavin Holmes")
(license LICENSE)

; (documentation https://url/to/documentation)

(package
  (name discord)
  (synopsis "Discord API library")
  (description "Discord API library for OCaml")
  (depends ocaml)
  (tags
    ("discord")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
