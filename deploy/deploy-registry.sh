# !/bin/bash

# Usage:
#   $ ./deploy/deploy-registry.sh
#   $ ./deploy/deploy-registry.sh --broadcast
#
# Description:
#   Deploys the Registry implementation and verifies the contract on relevant block explorer.
#   The script will deploy the contract on all the networks specified in the `deployments` array.
#   For ease of use, mainnets and testnets are separated into different arrays.
#
# Arguments:
#   --broadcast - (optional) If specified, the script will broadcast the transaction to the network. 

source .env

# Mainnets
deployments=(
    "1,mainnet,$ETHERSCAN_API_KEY"
    "137,polygon,$POLYGONSCAN_API_KEY"
    "10,optimism,$OPSCAN_API_KEY"
    "42161,arbitrum_one,$ARBISCAN_API_KEY"
    "43114,avalanche,$SNOWTRACE_API_KEY"
    "56,bnb_smart_chain,$BSCSCAN_API_KEY"
)

# Testnets
# deployments=(
    "5,goerli,$ETHERSCAN_API_KEY"
    "80001,polygon_mumbai,$POLYGONSCAN_API_KEY"
    "420,optimism_goerli,$OPSCAN_API_KEY"
    "421613,arbitrum_one_goerli,$ARBISCAN_API_KEY"
    "43113,avalanche_fuji,$SNOWTRACE_API_KEY"
    "97,bnb_smart_chain_testnet,$BSCSCAN_API_KEY"
# )

for deployment in "${deployments[@]}"; do
    IFS=',' read -r chain_id name api_key <<< "$deployment"

    export NETWORKS=$name

    echo "[$chain_id] ========= Deploying Registry implementation ========="

    output=$(forge script script/DeployRegistryImplementation.s.sol "$@")
    echo "$output"

    registry_impl=$(grep -m 1 "Deployed Registry implementation at" <<< "$output" | awk '{print $NF}')
    override_factory=$(grep -m 1 "Deployed OverrideFactory at" <<< "$output" | awk '{print $NF}')

    echo "[$chain_id] ========= Deployed Registry implementation at $registry_impl ========="

    if [ $# -gt 0 ]; then
        echo "[$chain_id] ========= Verifying the contract ========="
        forge verify-contract --watch \
            --chain $chain_id \
            --constructor-args $(cast abi-encode "constructor(address)" $override_factory) \
            $registry_impl \
            contracts/RoyaltyRegistry.sol:RoyaltyRegistry \
            $api_key
    else
        echo "[$chain_id] ========= Skipping verification ========="
    fi
done
