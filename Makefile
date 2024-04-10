# £ack this file was originally copied from https://github.com/Cyfrin/foundry-erc20-f23/blob/main/Makefile
# £todo: it needs a clean up.  

-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install Cyfrin/foundry-devops@0.0.11 --no-commit --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Verify already deployed contract - example 
verify:
	@forge verify-contract --chain-id 11155111 --num-of-optimizations 200 --watch --constructor-args 0x00000000000000000000000000000000000000000000d3c21bcecceda1000000 --etherscan-api-key $(OPT_ETHERSCAN_API_KEY) --compiler-version v0.8.19+commit.7dd6d404 0x089dc24123e0a27d44282a1ccc2fd815989e3300 src/OurToken.sol:OurToken


# NB: see mumbai for example of how to clean up the rest
###############################
# 			Sepolia testnet				#
###############################
SEPOLIA_FORK_ARGS := --fork-url $(SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS}
SEPOLIA_FORK_TEST_ARGS := --fork-url $(SEPOLIA_RPC_URL) 
SEPOLIA_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

sepoliaForkTest: 
	@forge test $(SEPOLIA_FORK_TEST_ARGS) 
	
sepoliaForkDeploy: 
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(SEPOLIA_FORK_ARGS)

sepoliaDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(SEPOLIA_ARGS)

###############################
# 		OPSepolia testnet				#
###############################
OPT_SEPOLIA_FORK_ARGS := --fork-url $(OPT_SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS}
OPT_SEPOLIA_FORK_TEST_ARGS := --fork-url $(OPT_SEPOLIA_RPC_URL) 
OPT_SEPOLIA_ARGS := --rpc-url $(OPT_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

optSepoliaForkTest: 
#	@forge test --match-test testCustomerCanClaimGift $(OPT_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# @forge test $(OPT_SEPOLIA_FORK_TEST_ARGS)  
#	@forge test $(OPT_SEPOLIA_FORK_TEST_ARGS) 
# ignores invariant tests.
	@forge test --match-test testNameDeployedLoyaltyProgramIsCorrect $(OPT_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# CardsToProgramToGifts // LoyaltyProgramTest // LoyaltyGiftTest // DeployLoyaltyProgramTest
	
optSepoliaForkDeploy: 
# @forge script script/DeployRegistry.s.sol:DeployRegistry $(OPT_SEPOLIA_FORK_ARGS)
# @forge script script/ComputeRegistryAddress.s.sol:ComputeRegistryAddress $(OPT_SEPOLIA_FORK_ARGS)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(OPT_SEPOLIA_FORK_ARGS)
#	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(OPT_SEPOLIA_FORK_ARGS)

optSepoliaDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(OPT_SEPOLIA_ARGS)
# @forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(OPT_SEPOLIA_ARGS)

#################################
# 	Base Sepolia testnet				#
################################# 
# Does not work yet. -- one test fails. 
BASE_SEPOLIA_FORK_ARGS := --fork-url $(BASE_SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS}
BASE_SEPOLIA_FORK_TEST_ARGS := --fork-url $(BASE_SEPOLIA_RPC_URL) 
BASE_SEPOLIA_ARGS := --rpc-url $(BASE_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

baseSepoliaForkTest: 
#	@forge test --match-test testCustomerCanClaimGift $(BASE_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# @forge test $(BASE_SEPOLIA_FORK_TEST_ARGS)  
#	@forge test --no-match-contract ContinueOnRevert $(BASE_SEPOLIA_FORK_TEST_ARGS)
# ignores invariant tests.
	@forge test --match-test testMintingCardsCreatesValidTokenBasedAccounts $(BASE_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# CardsToProgramToGifts // LoyaltyProgramTest // LoyaltyGiftTest // DeployLoyaltyProgramTest
	
baseSepoliaForkDeploy: 
# @forge script script/DeployRegistry.s.sol:DeployRegistry $(BASE_SEPOLIA_FORK_ARGS)
# @forge script script/ComputeRegistryAddress.s.sol:ComputeRegistryAddress $(BASE_SEPOLIA_FORK_ARGS)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(BASE_SEPOLIA_FORK_ARGS)
#	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(BASE_SEPOLIA_FORK_ARGS)

baseSepoliaDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(BASE_SEPOLIA_ARGS)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(BASE_SEPOLIA_ARGS)

#################################
# 			Mumbai testnet			  	#
################################# 
# Still fails on two tests 
MUMBAI_POLYGON_FORKED_TEST_ARGS := --fork-url $(MUMBAI_POLYGON_RPC_URL) 
MUMBAI_POLYGON_FORKED_DEPLOY_ARGS := --fork-url $(MUMBAI_POLYGON_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS} --verify --etherscan-api-key $(POLYGONSCAN_API_KEY)

mumbaiForkTest:  # notice that invariant tests are excluded (takes too long). 
	@forge test --no-match-contract ContinueOn $(MUMBAI_POLYGON_FORKED_TEST_ARGS) 

mumbaiForkedDeployTest: 
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(MUMBAI_POLYGON_FORKED_TEST_ARGS)

mumbaiForkedDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(MUMBAI_POLYGON_FORKED_DEPLOY_ARGS)

############################################## 
#     Arbitrum Sepolia testnet							 #
##############################################
ARB_SEPOLIA_FORK_TEST_ARGS := --fork-url $(ARB_SEPOLIA_RPC_URL) 
ARB_SEPOLIA_FORK_ARGS := --fork-url $(ARB_SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS} --verify --etherscan-api-key $(ETHERSCAN_API_KEY)
ARB_SEPOLIA_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

arbSepoliaForkTest: # notice that invariant tests are excluded (takes too long). 
	@forge test --no-match-contract ContinueOn $(ARB_SEPOLIA_FORK_TEST_ARGS)  

arbSepoliaTestDeploy: 
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ARB_SEPOLIA_FORK_TEST_ARGS)

arbSepoliaForkDeploy: 
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ARB_SEPOLIA_FORK_ARGS)
# @forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(ARB_SEPOLIA_FORK_ARGS)

arbSepoliaDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ARB_SEPOLIA_ARGS)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(ARB_SEPOLIA_ARGS)

# cast abi-encode "constructor(uint256)" 1000000000000000000000000 -> 0x00000000000000000000000000000000000000000000d3c21bcecceda1000000
# Update with your contract address, constructor arguments and anything else

###############################
# 			 Local testnet				#
###############################
ANVIL_ARGS_0 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_0) --broadcast
ANVIL_ARGS_1 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_1) --broadcast

anvilDeploy: # also initiates registry. 
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ANVIL_ARGS_1)





