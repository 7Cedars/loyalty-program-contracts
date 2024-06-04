# £ack this file was originally copied from https://github.com/Cyfrin/foundry-erc20-f23/blob/main/Makefile
-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install modules
install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

# Build
build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil --steps-tracing --block-time 1

# Verify already deployed contract - example 
verify:
	@forge verify-contract --chain-id 11155111 --num-of-optimizations 200 --watch --constructor-args 0x00000000000000000000000000000000000000000000d3c21bcecceda1000000 --etherscan-api-key $(OPT_ETHERSCAN_API_KEY) --compiler-version v0.8.19+commit.7dd6d404 0x089dc24123e0a27d44282a1ccc2fd815989e3300 src/OurToken.sol:OurToken

###############################
# 		OPSepolia testnet				#
###############################
OPT_SEPOLIA_FORKED_TEST_ARGS := --fork-url $(OPT_SEPOLIA_RPC_URL) 
OPT_SEPOLIA_FORKED_DEPLOY_ARGS := --rpc-url $(OPT_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(OPT_ETHERSCAN_API_KEY) -vvvv

# note: ignores invariant tests 
optSepoliaForkedTest: 
	@forge test --no-match-contract ContinueOn  $(OPT_SEPOLIA_FORKED_TEST_ARGS)

optSepoliaForkedDeployTest:
	@forge script script/DeployLoyaltyCard6551Account.s.sol:DeployLoyaltyCard6551Account $(OPT_SEPOLIA_FORKED_TEST_ARGS)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(OPT_SEPOLIA_FORKED_TEST_ARGS)
	
optSepoliaForkedDeploy: 
	@forge script script/DeployLoyaltyCard6551Account.s.sol:DeployLoyaltyCard6551Account $(OPT_SEPOLIA_FORKED_DEPLOY_ARGS)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(OPT_SEPOLIA_FORKED_DEPLOY_ARGS)

###############################
# 			 Local testnet				#
###############################
ANVIL_ARGS_0 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_0) --broadcast
ANVIL_TEST_ARGS := --rpc-url http://localhost:8545

anvilForkedTest: 
	@forge test --no-match-contract ContinueOn  $(ANVIL_TEST_ARGS)

# NB: DO NOT FORGET TO INITIATE REGISTRY, see https://docs.tokenbound.org/guides/deploy-registry for details. 
anvilDeploy:
	@forge script script/DeployLoyaltyCard6551Account.s.sol:DeployLoyaltyCard6551Account $(ANVIL_ARGS_0)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ANVIL_ARGS_1)
