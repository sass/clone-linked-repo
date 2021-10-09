This is a small utility action that clones a repository, using a ref linked from
a pull request if possible.

For example:

```yaml
jobs:
  sass-spec:
    name: Language Tests
    runs-on: ubuntu-latest

    strategy:
      fail-fast: false
      matrix:
        dart_channel: [stable, dev]
        async_label: [synchronous]
        async_args: ['']
        include:
          - dart_channel: stable
            async_label: asynchronous
            async_args: '--cmd-args --async'

    steps:
      - uses: actions/checkout@v2
      - uses: dart-lang/setup-dart@v1
        with: {sdk: stable}
      - uses: actions/setup-node@v2
        with: {node-version: 16}
      - run: dart pub get

      - name: Check out sass-spec
        uses: sass/clone-linked-repo@v1
        args: {repo: sass/sass-spec}
      - run: npm install
        working-directory: sass-spec
      - name: Run specs
        run: npm run sass-spec -- --dart .. $extra_args
        working-directory: sass-spec
        env: {extra_args: "${{ matrix.async_args }}"}
```

By default, this will clone `sass-spec`'s `main` branch into the `sass-spec`
path. But if a PR contains the text "sass/sass-spec#123" and there's a pull
request with ID 123, it will clone `pull/123/head` instead.

This action is meant primarily for Sass repositories. Other repositories are
welcome to use it, but please be aware that support will be a very low
priority.

## Details

* This will recognize both short references (`sass/sass-spec#123`) and full URLs
  (`https://github.com/sass/sass-spec/pulls/123`).

* This will ignore references to issues and closed pull requests.

* If the PR message contains multiple references to a PR from the same
  repository, this will use the first one.
