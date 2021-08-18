# MkDocs

A few lesser known (to me) features for better docs

## Code Blocks

Detailled docs here [here](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/#adding-line-numbers)

### code `hl_lines` and `linenums`
??? success "highlight lines in code blocks and show line numbers"
    [2021-08-18 08:08]  

    ```python hl_lines="2-3" linenums="42"
    class Foo:
        this = 'is highlighted'
        this = 'as well'
        this = 'not'
    ```
    via 
    ```
    ``python hl_lines="2-3" linenums="42"
    class Foo:
        this = 'is highlighted'
        this = 'as well'
        this = 'not'
    ``
    ```


## Inline

### keyboard modifier keys ++ctrl+alt+del++...
??? success "show nice symbols"
    [2021-08-18 08:08]  
    Simply type inline like this "`now hit ++ctrl+shift++-a`", rendered as "now hit ++ctrl+shift++-a"
    (with pymdownx.keys)

