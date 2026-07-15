# Rule: never commit secrets

`src/secrets.h` holds WiFi passwords and the API token. It is gitignored and must
stay that way. Never:

- commit `src/secrets.h` or remove it from `.gitignore`,
- paste its contents into other files, logs, or commit messages,
- hardcode credentials anywhere else in the tree.

Changes to the *shape* of secrets (new fields) go in `src/secrets.example.h`, with
placeholder values only.
