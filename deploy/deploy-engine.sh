deployments=(
    "1,mainnet,$ETHERSCAN_API_KEY"
    "5,goerli,$ETHERSCAN_API_KEY"
    "137,polygon,$POLYGONSCAN_API_KEY"
    "80001,polygon_mumbai,$POLYGONSCAN_API_KEY"
    "10,optimism,$OPSCAN_API_KEY"
    "420,optimism_goerli,$OPSCAN_API_KEY"
    "42161,arbitrum,$ARBISCAN_API_KEY"
    "421613,arbitrum_goerli,$ARBISCAN_API_KEY"
    "43114,avalanche,$SNOWTRACE_API_KEY"
    "43113,avalanche_fuji,$SNOWTRACE_API_KEY"
    "56,bnb_smart_chain,$BSCSCAN_API_KEY"
    "97,bnb_smart_chain_testnet,$BSCSCAN_API_KEY"
)

for deployment in "${deployments[@]}"; do
    IFS=',' read -r chain_id name api_key <<< "$deployment"

    export NETWORKS=$name

    echo "[$chain_id] ========= Deploying Engine implementation ========="

    output=$(forge script script/DeployEngineImplementation.s.sol "$@")
    echo "$output"

    engine_impl=$(grep -m 1 "Deployed Engine implementation at" <<< "$output" | awk '{print $NF}')
    fallback_registry=$(grep -m 1 "Deployed FallbackRegistry at" <<< "$output" | awk '{print $NF}')

    echo "[$chain_id] ========= Deployed Engine implementation at $engine_impl ========="

    if [ $# -gt 0 ]; then
        echo "[$chain_id] ========= Verifying the contract ========="
        forge verify-contract --watch \
            --chain $chain_id \
            $engine_impl \
            contracts/RoyaltyEngineV1.sol:RoyaltyEngineV1 \
            $api_key \
            --constructor-args $(cast abi-encode "constructor(address)" $fallback_registry)
    else
        echo "[$chain_id] ========= Skipping verification ========="
    fi
done
