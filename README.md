# LocalHexdocs

`LocalHexdocs` is a simple Elixir script allowing you to easily save and update [Hexdocs](https://hexdocs.pm/) files locally on your machine so you always have the most recent documentation for any Elixir, Erlang, or Gleam packages you might want to view.

List your desired Hexdocs packages in one or more files (in a `/packages` subdirectory... or automatically use the provided `default_packages.txt` file), then fetch the lastest Hexdocs for all packages to your local machine with:

```
elixir local_docs.exs get
```

Once downloaded, you can:
* [View your documents using the Caddy file server or something similar](#serving--viewing-your-local-hexdocs-files)
* [Search your documents using `grep` or something similar](#searching-through-your-local-hexdocs-files)
* [List your downloaded packages](#listing-hex-packages-with-downloaded-documentation)

You can also:

* List all packages with local Hexdocs:
```
elixir local_docs.exs list
```
* List all versions of all packages with local Hexdocs:
```
elixir local_docs.exs versions
```
* List all packages with multiple local Hexdocs versions:
```
elixir local_docs.exs multiple_versions
```
* See which package version directories `clean` would delete:
```
elixir local_docs.exs to_clean
```
* Delete older Hexdocs versions with:
```
elixir local_docs.exs clean
```

## Runs on Linux & Mac. Untested on Windows

I have tested `LocalHexdocs` on my own Linux and Mac machines but own no Windows machines and am unable to test on Windows.

## Performance & rate-limiting

During development and testing on 2025-03-16, performance was great until I hit the following:

```
"Failed to retrieve package information\nAPI rate limit exceeded for IP [IP address]\n** (MatchError) no match of right hand side value: nil\n
```

I decided to remove parallelization -- by setting `@max_concurrency` to just 1 -- to avoid overloading `hexdocs.pm` and to reduce the risk of getting rate-limited.

You can obviously change this module attribute to parallelize processing, but I'm not providing a configuration option for this to avoid pounding the `hexdocs.pm` server. Downloading documentation isn't something you need to happen instantaneously. Let's please be appreciative of and nice to our beloved `hexdocs.pm` server!

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

After cloning this repository, `cd` into it and specify which Elixir packages you wish to pull documentation for.

If you do nothing, running `elixir local_docs.exs get` in this directory will download all Hexdoc files for packages listed in the provided `default_packages.txt`. (There's nothing magical about `default_packages.txt`, which was simply my initial list of desired packages.)

You can modify `default_packages.txt` to add, remove, or comment out (with a leading "#") package names, but this may make it hard to update this project in the future, so I recommend that you:

1) Create a `/packages` subdirectory by running `mkdir packages`

2) Create at least one file containing at least one package name -- one line per package name -- within `/packages`

You can create a new file (with any name you desire) inside `/packages` and/or copy `popular_packages.txt` and/or `default_packages.txt` to the `/packages` subdirectory. For example:

```
cp popular_packages.txt packages/popular_packages.txt
```
or
```
cp default_packages.txt packages/packages.txt
```

It doesn't matter whether you create your own file(s) or copy files from elsewhere.

You can name these files anything you want. All files in the `/packages` directory will be combined (and the concatenated list of package names de-duped). So you could include, for example, a list of packages you personally use, a list of packages your company uses, and a copy of `popular_packages.txt`.

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

All package names (one per line) in all files in the `/packages` directory will be merged into a list of packages to pull documentation for. You can create multiple files, and it's fine if the same package appears more than once, as we de-duplicate before pulling. Again, each package name should be listed on its own line.

We recommend creating a `/packages` subdirectory, but you can instead create a `packages.txt` file in the top-level directory or rely on `default_packages.txt`.

If you don't create a `/packages` directory, only `default_packages.txt` or `packages.txt` will be used from the top-level directory. All other files will be ignored as a source of package names.

`packages/*` and `packages.txt` are listed in `.gitignore`, so updating this repository will not modify/delete your `./packages.txt` file or any files you save in `packages/`. You can safely customize them and make them your own.

### Running `LocalHexdocs`

Once you're happy with your package configuration (whether you choose to create a `packages.txt` file or files in `/packages/` or use the `default_packages.txt` file), you can pull down the latest documentation for each package with this command, executed from the main directory:

```
elixir local_docs.exs get
```

(I didn't bother creating an executable binary since anyone wanting to download Hexdocs probably already has Elixir installed.)

You will see a stream of output, with one line per package. Each should say one of the following:

* "Docs fetched: /home/user_name/.hex/docs/hexpm/scholar/0.4.0"
* "No package with name made_up_library"
* "Docs already fetched: /home/user_name/.hex/docs/hexpm/sobelow/0.13.0"

After all packages have processed, you should see an Elixir map summarizing what happened.

It contains four keys, each with a list of package names, like:

```
%{
  "Couldn't find docs" => ["coveralls", "cowboy", "iconv", "luerl", "stun"],
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

After downloading your Hexdoc files, you'll want to view them.

#### Viewing Hexdocs for one package

Hex.docs makes it easy to view -- in your default browser -- Hexdocs for a particular package with:
```
mix hex.docs offline PACKAGE_NAME
```

#### Viewing Hexdocs for all packages

One way to browse and view Hexdocs for *all* your packages is with `caddy file-server` (see: [CaddyServer.com](https://caddyserver.com/) and [the Caddy Github repo](https://github.com/caddyserver/caddy)). The following will serve your Hexdocs on port 8888 (assuming your `hexpm` directory is at `~/.hex/docs/hexpm`):

```
cd ~/.hex/docs/hexpm
caddy file-server --browse --listen :8888
```

### Searching through your local Hexdocs files

Downloading documentation makes it easily searchable, so if you download the most popular Elixir/Erlang/Gleam packages' documentation, you can search through them all to discover potentially useful packages.

For example, if you're curious which Elixir packages use [JOSE](https://jose.readthedocs.io/en/latest/), you can run this query:

```
$ grep -rl "JOSE" ~/.hex/docs/hexpm
```

Which should list all files containing "JOSE":
```
...
./joken/2.6.2/Joken.Signer.html
./joken/2.6.2/Joken.html
./joken/2.6.2/api-reference.html
...
./jose/1.11.10/jose_jwk_oct.html
./jose/1.11.10/jose_jwk_openssh_key.html
./jose/1.11.10/jose_jwk_pem.html
./jose/1.11.10/jose_jwk_set.html
./jose/1.11.10/jose_jwk_use_enc.html
...
./livebook/0.15.4/custom_auth.html
./livebook/0.15.4/dist/search_data-CE645AD5.js
./oidcc/3.3.0/Oidcc.ClientContext.html
./oidcc/3.3.0/Oidcc.ProviderConfiguration.Worker.html
./oidcc/3.3.0/Oidcc.ProviderConfiguration.html
...
```

### Listing Hex packages with downloaded documentation

To view a list of all Hex packages with downloaded Hexdocs, run:

```
elixir local_docs.exs list
```

Returns something like:
```
Packages downloaded in /home/user_name/.hex/docs/hexpm: ["abacus", "absinthe", "absinthe_constraints", "absinthe_error_payload",
 "absinthe_federation", "absinthe_graphql_ws", "absinthe_phoenix",
 "absinthe_plug", "absinthe_relay", "absinthe_relay_keyset_connection",
 "accept", "accessible", "airports", "alembix", "amqp", "amqp_client",
 ...
 "zigler", "zipper", "zstream", "zxcvbn"]
]
```

### Listing all Hex package versions with downloaded documentation

```
elixir local_docs.exs versions
```

Returns something like:

```
Packages downloaded in /home/user_name/.hex/docs/hexpm: [
  ...
  wallaby: ["0.30.10"],
  web_driver_client: ["0.2.0"],
  websock: ["0.5.3"],
  websock_adapter: ["0.5.8"],
  websockex: ["0.4.3"],
  wisp: ["1.5.3"],
  word_smith: ["0.2.0"],
  worker_pool: ["6.4.0"],
  workos: ["1.1.0"],
  ...
]
```

### Listing all Hex package versions with multiple versions of downloaded documentation

```
elixir local_docs.exs multiple_versions
```
Returns something like:
```
Packages downloaded in /home/user_name/.hex/docs/hexpm with multiple versions: [absinthe: ["1.7.8", "1.7.9"], appsignal: ["2.15.1", "2.15.2"]]
```

### Removing older Hexdoc versions from packages with multiple versions

```
elixir local_docs.exs to_clean
```
Returns something like:
```
Packages with multiple Hexdocs versions in /home/user_name/.hex/docs/hexpm: [
  %{
    delete: ["1.7.8"],
    keep: "1.7.9",
    package: "absinthe",
    delete_dirs: ["/home/user_name/.hex/docs/hexpm/absinthe/1.7.8"]
  },
  %{
    delete: ["2.15.1"],
    keep: "2.15.2",
    package: "appsignal",
    delete_dirs: ["/home/user_name/.hex/docs/hexpm/appsignal/2.15.1"]
  },
  %{
    delete: ["3.4.68"],
    keep: "3.4.69",
    package: "ash",
    delete_dirs: ["/home/user_name/.hex/docs/hexpm/ash/3.4.68"]
  },
  ...
  %{
    delete: ["4.12.0", "4.13.0"],
    keep: "5.0.0",
    package: "prometheus",
    delete_dirs: ["/home/user_name/.hex/docs/hexpm/prometheus/4.12.0",
     "/home/user_name/.hex/docs/hexpm/prometheus/4.13.0"]
  },
  %{
    delete: ["0.5.8"],
    keep: "0.5.9",
    package: "req",
    delete_dirs: ["/home/user_name/.hex/docs/hexpm/req/0.5.8"]
  },
  ...
]
```

To delete the directories listed in `delete_dirs`, run:

```
elixir local_docs.exs clean
```

This should return:
```
"Deleting /home/user_name/.hex/docs/hexpm/absinthe/1.7.8"
"Deleting /home/user_name/.hex/docs/hexpm/appsignal/2.15.1"
"Deleting /home/user_name/.hex/docs/hexpm/ash/3.4.68"
...
"Deleting /home/user_name/.hex/docs/hexpm/prometheus/4.12.0"
"Deleting /home/user_name/.hex/docs/hexpm/prometheus/4.13.0"
"Deleting /home/user_name/.hex/docs/hexpm/req/0.5.8"
...
```

### Updating your Hexdocs documentation

Updating your local Hexdocs documentation is as simple as re-running:

```
elixir local_docs.exs get
```

Each time you run this, `LocalHexdocs` will pull the latest version of documentation for each specified package.

To ensure you always have the latest documentation, you might create a cron job to periodically run `elixir local_docs.exs get` (...but please don't run it too frequently or you'll needlessly hammer the Hexdocs.pm server).

## Known issues & possible future features

* After getting all files, look for packages with multiple versions. If present:
  * Provide instructions for removing the older versions
  * Offer to immediately remove the older versions
  * (Based on user config/options) Automatically remove documentation of outdated package versions, with option to keep older versions
* Handle "** (MatchError) no match of right hand side value: {:error, :eacces}\n    (hex 2.0.6) lib/mix/tasks/hex.docs.ex:377: Mix.Tasks.Hex.Docs.extract_docs/2\n    (mix 1.16.1) lib/mix/task.ex:478: anonymous fn/3 in Mix.Task.run_task/5\n    (mix 1.16.1) lib/mix/cli.ex:96: Mix.CLI.run_task/2\n    /Users/jameslavin/.asdf/installs/elixir/1.16.1-otp-26/bin/mix:2: (file)"
* Recommend grep command that doesn't generate so many "grep: /home/.../.hex/docs/hexpm/mist/4.0.7/fonts/ubuntu-mono-v15-regular-latin.woff2: Permission denied"
* Improve the new unified command-line API
* `elixir local_docs.exs list` could display (perhaps optionally) the individual and total size of downloaded documentation
* Function for listing all desired packages without downloaded documentation
* Option to load only the top-N popular packages from `popular_packages.txt`
* Display "amqp_client/4.0.3" as "amqp_client (4.0.3)"?
* Regularly update `popular_packages.txt` from current https://hex.pm/packages
* Create `awesome_packages.txt` package list containing all packages in https://github.com/h4cc/awesome-elixir?
* Should more be done to further avoid pounding `hexdocs.pm` and avoid triggering rate limiting (e.g., pausing between pulls) or is it okay now that I've suppressed parallelization by default?

## Author

`LocalHexdocs` was created by [James Lavin](https://www.jameslavin.com), an [Elixir](https://elixir-lang.org/) programmer who also loves [R (statistics)](https://www.r-project.org/), [Linux](https://www.linux.org/), [PostgreSQL](https://www.postgresql.org/), and running his [Kubernetes](https://kubernetes.io/)+[Cilium](https://cilium.io/)+[Helm](https://helm.sh/)+[Podman](https://podman.io/)+[CloudNativePG](https://cloudnative-pg.io/)+[Cert-manager](https://cert-manager.io/) cluster.

