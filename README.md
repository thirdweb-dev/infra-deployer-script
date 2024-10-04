### Getting Started

- Grab a base sepolia RPC URL from thirdweb
- Grab a etherscan API key
- run the following command in the terminal

```bash
forge script --chain 84532 script/InfraDeployer.s.sol:InfraDeployerScript --rpc-url $BASE_SEPOLIA_RPC_URL --broadcast --verify --slow -vvvv
```
