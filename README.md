# gists
Collections of code snippets in [GitHub Gist](https://gist.github.com/hwakabh) with git-subomodule.

## Sync manually
To automatically sync changes of submodules in [Gist](https://gist.github.com), the following operation will be required when we change snippets in Gist for manually applying changes into this repository.

```shell
# Fetch latest changes from Gists side into this repository
% git submodule update --remote

% git add .
% git commit -m "chore: updated submodules"
% git push
```

Note that these operations requires to clone this repo recursively, whereas by default `git clone` does not do this.
```shell
% git clone --recursive git@github.com:hwakabh/gists.git
% git fetch --all --prune --recurse-submodules=yes
```

## Configurations
As we are using GitHub Actions to sync contents autocatically between this repo and Gists, which is mentioned above, the token is required for it. \
For the token to push changes to this repo for sync, the following permission would be required:

User permissions:
- gist: Read and Write

Repository permissions:
- metadata: Read
- contents: Read and Write

Please see more details in [official document](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) for generating tokens on GitHub.
