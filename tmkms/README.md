# Install and setup tmkms for validator nodes

## Introduction

This repo intends to provide a quick and easy way for validator operators to deploy tmkms soft signing for each validator in a quick and efficient way. The instructions can be used to deploy multiple TMKMS instances in a single server to serve signing keys to many networks at once.

The heavy lifting is undertaken by the included scripts `install_tmkms.sh` and `install_tmkms_service.sh`.

For advanced devops persons, the same could be achieved using Ansible or other deployment automation solutions.

This repo builds on the work of Dilan (Imperator) and Schultzie (Lavendar Five).

If you see a problem with this doc, fix it and PR like a good community chad.

## TMKMS Installation

This guide has been developed with the folowing assumptions:
- The user is running a debian/ubuntu server environment (most linux distros should work)
- The user has configured a non-root user with `sudo`. 
- The user has no password for `sudo`.
- The user has instanciated a validator and has the `priv_validator_key.json` available.

### Install Cargo

Download and execute the install script
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
Source the `env` file
```bash
source $HOME/.cargo/env
```

### Update install toolchain

```bash
sudo apt update
sudo apt upgrade -y 
sudo apt install make build-essential gcc git jq chrony libusb-1.0-0-dev -y
```

### Install TMKMS

```bash
cd $HOME
git clone https://github.com/iqlusioninc/tmkms.git
cd $HOME/tmkms
cargo install tmkms --features=softsign

# confirm it works
which tmkms
```

Initialise TMKMS and generate signing softsign key

```bash
cd $HOME
touch kms
cd kms
tmkms init config
tmkms softsign keygen $HOME/kms/config/secrets/secret_connection_key
```

Using a tool like `tree` you can then verify the folder structure is as expected, relative to `$HOME`:

```bash
tree kms

kms
└── config
    ├── schema
    ├── secrets
    │   ├── kms-identity.key
    │   └── secret_connection_key
    ├── state
    └── tmkms.toml
```

### Add blockchain to TMKMS

We will now add a blockchain to TMKMS. The script  requires the following information which is passed to the script at execution:
- validator ip
- validator port (we specify on the validator nodes `config.toml` later)
- chain-id of the network we are adding
- the bech32 prefic for the chain we are adding (i.e `juno`)
- path to your `priv_validator_key.json`

For the sake of illustration we will assume that we are using uni-2 testnet network, with some made up server information.

The script accepts arguments as follows:

- `validator_ip` is the ip of the validator box
- `validator_port` is the port you set `priv_validator_laddr` to _on_ that box
- `chain_id` is what you think it is
- `prefix` is the denom prefix, e.g. `juno`, `stars`

```bash
./install_tmkms.sh <validator_ip> <validator_port> <chain_id> <prefix> <path/to/priv_validator_key.json>
```

Start by cloning the script repo and setting script permissions
```bash
cd $HOME
git clone https://github.com/nullmames/cosmos-tools.git
cd cosmos-tools/tmkms

chmod 700 install_tmkms.sh && chmod 700 install_tmkms_service.sh
```

Copy your `priv_validator_key.json` to `$HOME/cosmos-tools/tmkms/`. **Note** that the script will delete this file after usage, so **be sure it it backed up elsewhere**.

Execute the TMKMS network setup script:

```bash
./install_tmkms.sh 145.754.864.2 26659 uni-2 juno $HOME/cosmos-tools/tmkms/priv_validator_key.json
```

Note that in this example, `26659` is the port you will need to open on your validator box.

### Add TMKMS service for blockchain

The script accepts arguments as follows:

```bash
./install_tmkms_service.sh <chain_id>
```

Note that this script uses `sudo` commands; If you require a password for sudo, then you may need to run a sudo command before you run this script, or just run all the commands in the script via copy-pasta methods. If you know a better way, make a PR.

Execute the service install script:

```bash
./install_tmkms_service.sh uni-2
```

## Validator setup

You will need to edit the `config.toml` for your validator. This is usually stored in `$HOME/.<chain>d/config/`. If you can't find it, renounce your validator membership and plead with your delegators to redelegate.

Find and set the following configuration parameters. This will enable your validator to listen for TMKMS to send the signing key.

```toml
priv_validator_laddr = "tcp://<validator_ip>:<validator_port>"
```

Note that if you've followed the commands _exactly as above_, then TMKMS will be expecting the service to be open on port `26659`.

This means you will want to set:

```toml
priv_validator_laddr = "tcp://0.0.0.0:26659"
```

Comment out the following configuration parameters. This will tell your validator to ignore the local keys.

```toml
# priv_validator_key_file = "config/priv_validator_key.json"
# priv_validator_state_file = "data/priv_validator_state.json"
```

Restart your node and check you logs
```bash
sudo systemctl restart <chain-service>
journalctl -fu <chain-service>
```

Once you have confirmed you are signing you can then set your firewall rules to allow connection to <validator_port>. It would be a good idea to whitelist just your TMKMS server for this port.

You should completely firewall all inbound connections to your TMKMS server (except perhaps ssh), unless you are running other services (not recommended for security).

If using ufw this will look something like (as root):

    sudo ufw allow from <tmkms_box_ip> to any port 26659

Your validator logs should look as they always do.

If you see errors complaining about a pubkey and a crashloop, check your firewall, as likely your validator cannot reach the remote signer.

Your TMKMS logs should look similar to the following.

```bash
signed PreVote:05443FAB81 at h/r/s 150224/0/1 (0 ms)
signed PreCommit:05443FAB81 at h/r/s 150224/0/2 (0 ms)
signed PreVote:C14434A06A at h/r/s 150225/0/1 (0 ms)
signed PreCommit:C14434A06A at h/r/s 150225/0/2 (0 ms)
```

## Further reading
https://github.com/iqlusioninc/tmkms

