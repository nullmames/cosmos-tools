# Read inputs
VALIDATOR_IP=$1
VALIDATOR_PORT=$2
CHAIN_ID=$3
UNIT=$4
PATH_PRIV_VALIDATOR_KEY=$5

# Set file names
TOML_FILE=${HOME}/kms/config/tmkms-${CHAIN_ID}.toml
STATE_FILE=${HOME}/kms/config/state/${CHAIN_ID}-consensus.json
SECRET_FILE=${HOME}/kms/config/secrets/${CHAIN_ID}-consensus.key

mkdir -p ${HOME}/kms/config/state/
mkdir -p ${HOME}/kms/config/secrets/

# Import and init keys
tmkms softsign import $PATH_PRIV_VALIDATOR_KEY $SECRET_FILE

# Delete original keyfile
rm -rf $PATH_PRIV_VALIDATOR_KEY

# Create network configuration for tmkms
echo "[INFO] Writing $TOML_FILE..."

cat >$TOML_FILE <<EOF
# Chain Configuration
[[chain]]
id = "${CHAIN_ID}"
key_format = { type = "bech32", account_key_prefix = "${UNIT}pub", consensus_key_prefix = "${UNIT}valconspub" }
state_file = "${STATE_FILE}"

# Software-based Signer Configuration
[[providers.softsign]]
chain_ids = ["${CHAIN_ID}"]
key_type = "consensus"
path = "${SECRET_FILE}"

# Validator Configuration
[[validator]]
chain_id = "${CHAIN_ID}"
addr = "tcp://${VALIDATOR_IP}:${VALIDATOR_PORT}"
secret_key = "${HOME}/kms/config/secrets/kms-identity.key"
protocol_version = "v0.34"
reconnect = true
EOF

