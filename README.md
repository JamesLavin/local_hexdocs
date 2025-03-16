# LocalHexdocs

`LocalHexdocs` is a simple Elixir script allowing you to easily save and update [Hexdocs](https://hexdocs.pm/) files locally on your machine so you always have the most recent documentation for any Elixir, Gleam, or Erlang packages you might want to view.

List your desired Elixir packages in a `packages.txt` file (in either this project's directory or in a `/packages` subdirectory), then run `elixir save_hexdocs.ex` to pull down the lastest Hexdocs for all packages to your local machine.

You can view your documents using the [Caddy](https://caddyserver.com) file server or something similar.

## Runs on Linux & Mac. Untested on Windows

I have tested this library on my own Linux and Mac machines but own no Windows machines and am unable to test on Windows.

## Missing feature: Rate-limiting

During development and testing on 2025-03-16, I hit the following, which I need to think through.

```
"Failed to retrieve package information\nAPI rate limit exceeded for IP [IP address]\n** (MatchError) no match of right hand side value: nil\n
```

## Usage

### Pulling down this repository

Before you can run `LocalHexdocs`, you must run `git clone` to download this repository. (Alternatively, you could manually copy the files from https://github.com/JamesLavin/local_hexdocs without downloading the repository, but pulling any future changes would be harder.)

```
git clone git@github.com:JamesLavin/local_hexdocs.git
```

OR

```
git clone https://github.com/JamesLavin/local_hexdocs.git
```

### Updating this repository

To pull future `LocalHexdocs` updates, cd into this repository and run:

```
git pull origin main
```

### Specifying Hexdocs packages you want to save locally

After pulling down this repository, the next step is `cd`-ing into the top directory of this repository and specifying which Elixir packages you wish to pull documentation for.

If you do nothing, running `elixir save_hexdocs.ex` in this directory will download all Hexdoc files for packages listed in the provided `default_packages.txt`. (There's nothing magical about `default_packages.txt`, which was simply my initial list of desired packages.)

You can modify `default_packages.txt` to add, remove, or comment out (with a leading "#") packages, but this may make it hard to update this project in the future, so we recommend that you:

1) Create a `/packages` subdirectory by running `mkdir packages`

2) Create at least one file within `/packages` containing at least one package name

You can create a new file (with any name you desire) inside `/packages` and/or you can copy `popular_packages.txt` and/or `default_packages.txt` to the `/packages` subdirectory. For example:

```
cp popular_packages.txt packages/popular_packages.txt
```
or
```
cp default_packages.txt packages/packages.txt
```

It doesn't matter whether you create your own file(s) or copy files from elsewhere.

You can name these files anything you want. All files in the `/packages` directory will be used.

You can modify the files' content by adding/removing package names (one package per line) and/or adding comments (starting with #"). For example:

`my_packages.txt`:
```
# This is my list of packages
elixir
gleam
phoenix
phoenix_live_view
ecto
ex_aws_s3
```

All packages names (one per line) in all files in the `/packages` directory will be merged into a list of packages to pull documentation for. You can create multiple files, and it's fine if the same package appears more than once, as we de-duplicate before pulling. Again, each package name should be listed on its own line.

You don't need to create a separate `/packages` subdirectory, but we recommend doing so.

If you don't create a `/packages` directory, only `default_packages.txt` or `packages.txt` will be used from the top-level directory. All other files will be ignored as a source of package names.

`packages/*` and `packages.txt` are listed in `.gitignore`, so updating this repository will not modify/delete your `./packages.txt` file or any files you save in `packages/`. You can safely customize them and make them your own.

### Running `LocalHexdocs`

Once you're happy with your package configuration (whether you choose to create a `packages.txt` file or `/packages/*.txt` files or use the `default_packages.txt` file), you can run this script to pull down the latest documentation for each library with this command, executed from the main directory :

```
elixir save_hexdocs.ex
```

(I didn't bother creating an executable binary since anyone wanting to download Hexdocs probably already has Elixir installed.)

You will see a stream of output, with one line per library. Each should say one of the following:

* "Docs fetched: /home/mateusz/.hex/docs/hexpm/scholar/0.4.0"
* "No package with name made_up_library"
* "Docs already fetched: /home/mateusz/.hex/docs/hexpm/sobelow/0.13.0"

At the end, you should see an Elixir map with three keys, each with a list of library names, like:

```
%{
  "Docs already fetched" => ["amqp/4.0.0", "amqp_client/4.0.3", "axon/0.7.0",
   "bamboo/2.4.0", "bamboo_phoenix/1.0.0", "bamboo_smtp/4.2.2", "bandit/1.6.8",
   "bcrypt_elixir/3.2.1", "benchee/1.3.1", "bodyguard/2.4.3", "broadway/1.2.1",
   ...
   "vega_lite/0.1.11", "vix/0.33.0", "wallaby/0.30.10", "websock/0.5.3",
   "websock_adapter/0.5.8", "xla/0.8.0", "yamerl/0.10.0", "yaml_elixir/2.11.0",
   "zigler/0.13.3"],
  "Docs fetched" => ["live_svelte/0.15.0", "req/0.5.8", "sobelow/0.13.0"],
  "No package with name" => ["made_up_library", "not_real"]
}
```

### Serving & viewing your local Hexdocs files

Once you have downloaded your Hexdoc files locally, one way to view them is using `caddy file-server` (see: [CaddyServer.com](https://caddyserver.com/) and [the Caddy Github repo](https://github.com/caddyserver/caddy)). The following will serve your Hexdocs on port 8888 (assuming your `hexpm` directory is at `~/.hex/docs/hexpm`):

```
cd ~/.hex/docs/hexpm
caddy file-server --browse --listen :8888
```

### Searching through your local Hexdocs files

Downloading documentation makes it easily searchable, so if you download the most popular Elixir packages' documentation, you can search through it to discover potentially valuable packages.

For example, if you're curious which Elixir packages use [JOSE](https://jose.readthedocs.io/en/latest/), you can run this query:

```
$ grep -rl "JOSE" ~/.hex/docs/hexpm
...
./joken/2.6.2/Joken.Signer.html
./joken/2.6.2/Joken.html
./joken/2.6.2/api-reference.html
./joken/2.6.2/changelog.html
./joken/2.6.2/dist/search_data-2420A17A.js
./joken/2.6.2/introduction.html
./joken/2.6.2/migration_from_1.html
...
./jose/1.11.10/jose_jwk_oct.html
./jose/1.11.10/jose_jwk_openssh_key.html
./jose/1.11.10/jose_jwk_pem.html
./jose/1.11.10/jose_jwk_set.html
./jose/1.11.10/jose_jwk_use_enc.html
./jose/1.11.10/jose_jwk_use_sig.html
./jose/1.11.10/jose_jws.html
./jose/1.11.10/jose_jws_alg.html
./jose/1.11.10/jose_jws_alg_ecdsa.html
./jose/1.11.10/jose_jws_alg_eddsa.html
./jose/1.11.10/jose_jws_alg_hmac.html
...
./livebook/0.15.4/custom_auth.html
./livebook/0.15.4/dist/search_data-CE645AD5.js
./oidcc/3.3.0/Oidcc.ClientContext.html
./oidcc/3.3.0/Oidcc.ProviderConfiguration.Worker.html
./oidcc/3.3.0/Oidcc.ProviderConfiguration.html
./oidcc/3.3.0/Oidcc.Token.html
./oidcc/3.3.0/Oidcc.html
...
```

### Updating your Hexdocs documentation

Updating your local Hexdocs documentation is as simple as re-running:

```
elixir save_hexdocs.ex
```

Each time you run this, `LocalHexdocs` will pull the latest version of documentation for each specified library.

If you want to ensure you always have the latest documentation, you might create a cron job to periodically run `elixir save_hexdocs.ex`.

## Possible future features

* Avoid triggering rate limits
* If this triggers a rate limit, stop trying to pull
* Option for loading only the top-N popular packages from popular_packages.txt
* Handle responses like "Couldn't find docs for package with name cqerl or version 2.1.3"
* De-duplicate & sort packages before processing/displaying them?
* Command for removing documentation of outdated package versions
* Option for automatically removing documentation of outdated package versions
* Display "amqp_client/4.0.3" as "amqp_client (4.0.3)"?
* Sample popular_packages.txt with top N packages in https://hex.pm/packages?
* Sample awesome_packages.txt with all packages in https://github.com/h4cc/awesome-elixir?

## Author

`LocalHexdocs` was created by James Lavin.

