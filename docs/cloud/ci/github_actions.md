# Github Actions

## Notable Features

- Blazing FAST pick up after push
- declarative yaml
- cache!!
- artifacts
- local runners
- build matrix does not interfere with other builds, run in seperate containers obviously (e.g. tmux
  flows did not collide, allthough parallel)
- slick UI

## Example Python Project

??? "Normal Python (with caching)"

    Thanks (yet again), [Timothy](https://github.com/pawamoy/copier-poetry)

    ```yaml
    name: ci

    on:
      push:
        branches:
          - master
      pull_request:
        branches:
          - master

    defaults:
      run:
        shell: bash

    env:
      LANG: "en_US.utf-8"
      LC_ALL: "en_US.utf-8"
      POETRY_VIRTUALENVS_IN_PROJECT: "true"
      PYTHONIOENCODING: "UTF-8"

    jobs:
      quality:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout
            uses: actions/checkout@v2

          - name: Set up Python 3.6
            uses: actions/setup-python@v1
            with:
              python-version: 3.8

          - name: Set up the cache
            uses: actions/cache@v1
            with:
              path: .venv
              key: cache-python-packages-2

          - name: Set up the project
            run: |
              pip install poetry safety
              poetry install -v

          - name: Check if the documentation builds correctly
            run: poetry run duty check-docs

          - name: Check the code quality
            run: poetry run duty check-code-quality

          - name: Check if the code is correctly typed
            run: poetry run duty check-types

          - name: Check for vulnerabilities in dependencies
            run: poetry run duty check-dependencies

      tests:
        strategy:
          max-parallel: 6
          matrix:
            os: [ubuntu-latest, macos-latest, windows-latest]
            python-version: [3.6, 3.7, 3.8]

        runs-on: ${{ matrix.os }}

        steps:
          - name: Checkout
            uses: actions/checkout@v2

          - name: Set up Python ${{ matrix.python-version }}
            uses: actions/setup-python@v1
            with:
              python-version: ${{ matrix.python-version }}

          - name: Set up the cache
            uses: actions/cache@v1
            env:
              cache-name: cache-python-packages
            with:
              path: .venv
              key: ${{ matrix.os }}-${{ matrix.python-version }}-${{ env.cache-name }}-2

          - name: Set up the project
            run: |
              pip install poetry
              poetry install -v

          - name: Run the test suite
            run: poetry run duty test
    ```

## $PATH / sourcing files

How to activate conda, i.e. get the PATH expanded.

- The problem with those step by step tools is that every bash action is run in a subshell. I.e. you cannot source files or export vars for all others there.
- Also they do not allow to ref env when setting env vars.

See

- [here](https://github.com/actions/setup-go/issues/14)...
- [here](https://github.com/firepress-org/rclone-in-docker/blob/master/.github/workflows/ci_dockerfile_is_master.yml)

for crazy "solutions" around.

- Official "solution" to PATH is also ridiculous: The put ALL in - but not conda:

```bash
echo $PATH
/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/runner/.local/bin:/opt/pipx_bin:/usr/share/rust/.cargo/bin:/home/runner/.config/composer/vendor/bin:/usr/local/.ghcup/bin:/home/runner/.dotnet/tools:/snap/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/home/runner/.dotnet/tools
```

:smile:

Means: We also have to hardcode it:

```yaml
env:
  MC: "/home/runner/miniconda3"
  PATH: "$(MC)/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"
```


## My Conda Driven Flow

### Local: 
- I have my presets in `<project root>/environ`, which is automatically sourced on cd into it.
- It sets `$PROJECT` and `$pyver`, parametrizing fully the conda env for the project.
- Sources make
- Calls `activate_venv` function -> all set, with the default dev python env

### CI:
- `$PROJECT` is global in env
- `$pyver` per buildmatrix version
- cached is the root `$HOME/miniconda3`
- also cached the pyver specific envs, containing all pip installs.
- cache name for the latter: `cache_name: cache-miniconda-envs-${{ env.PROJECT }}_py${{ matrix.python-version }}_${{ hashFiles('pyproject.toml') }}`

!!! tip "Deletion of Old Caches"
    GH deletes the caches unused for 7 days.

```yaml lp mode=show_file fn=.github/workflows/ci.yml
```









