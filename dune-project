(lang dune 3.24)
(name discord)
(generate_opam_files true)

(source
  (github gavrh/discordml))

(authors "Gavin Holmes")
(maintainers "Gavin Holmes")
(license MIT)

; (documentation https://url/to/documentation)

(package
  (name discord)
  (synopsis "Discord API library")
  (description "Discord API library for OCaml")
  (depends
    (ocaml (>= 5.2))
    eio
    eio_main
    cohttp-eio
    http
    uri
    tls
    tls-eio
    ca-certs
    yojson
    ppx_deriving
    ppx_deriving_yojson
    dotenv
    domain-name
    digestif
    mirage-crypto-rng)
  (tags
    ("discord")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
