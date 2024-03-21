# this is copy past from https://github.com/Cyfrin/foundry-erc20-f23/blob/main/Makefile
# Need to adapt this later on. 

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

# The following (from patrick C) I find a bit overkill.. 
# ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
# 	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account dev_2 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
# endif

###############################
# 			 Local testnet				#
###############################
ANVIL_ARGS_0 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_0) --broadcast
ANVIL_ARGS_1 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_1) --broadcast
ANVIL_ARGS_2 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_2) --broadcast
ANVIL_ARGS_3 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_3) --broadcast
ANVIL_ARGS_4 := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY_4) --broadcast

anvilAll: 
	@forge script script/DeployRegistry.s.sol:DeployRegistry $(ANVIL_ARGS_0)
	@forge script script/ComputeRegistryAddress.s.sol:ComputeRegistryAddress $(ANVIL_ARGS_0)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ANVIL_ARGS_1)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(ANVIL_ARGS_4)
	@forge script script/Interactions.s.sol:Interactions $(ANVIL_ARGS_1)

anvilInitiate:
	@forge script script/DeployRegistry.s.sol:DeployRegistry $(ANVIL_ARGS_0)
	@forge script script/ComputeRegistryAddress.s.sol:ComputeRegistryAddress $(ANVIL_ARGS_0)

anvilDeployProgram:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ANVIL_ARGS_1)

anvilDeployGifts:
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(ANVIL_ARGS_4)

anvilInteractions: 
	@forge script script/Interactions.s.sol:Interactions $(ANVIL_ARGS_1)

###############################
# 			Sepolia testnet				#
###############################
SEPOLIA_FORK_ARGS := --fork-url $(SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS}
SEPOLIA_FORK_TEST_ARGS := --fork-url $(SEPOLIA_RPC_URL) 
SEPOLIA_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

sepoliaForkTest: 
#	@forge test --match-test testCustomerCanClaimGift $(SEPOLIA_FORK_TEST_ARGS) -vvvv 
	@forge test $(SEPOLIA_FORK_TEST_ARGS)  
# @forge test --match-contract CardsToProgramToGifts $(SEPOLIA_FORK_TEST_ARGS) 
# CardsToProgramToGifts // LoyaltyProgramTest // LoyaltyGiftTest // DeployLoyaltyProgramTest
	
sepoliaForkDeploy: 
# @forge script script/DeployRegistry.s.sol:DeployRegistry $(SEPOLIA_FORK_ARGS)
# @forge script script/ComputeRegistryAddress.s.sol:ComputeRegistryAddress $(SEPOLIA_FORK_ARGS)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(SEPOLIA_FORK_ARGS)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(SEPOLIA_FORK_ARGS)

sepoliaDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(SEPOLIA_ARGS)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(SEPOLIA_ARGS)

# Very much WIP 
###############################
# 		OPSepolia testnet				#
###############################
OPT_SEPOLIA_FORK_ARGS := --fork-url $(OPT_SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS}
OPT_SEPOLIA_FORK_TEST_ARGS := --fork-url $(OPT_SEPOLIA_RPC_URL) 
OPT_SEPOLIA_ARGS := --rpc-url $(OPT_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

optSepoliaForkTest: 
#	@forge test --match-test testCustomerCanClaimGift $(OPT_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# @forge test $(OPT_SEPOLIA_FORK_TEST_ARGS)  
	@forge test --no-match-contract ContinueOnRevert $(OPT_SEPOLIA_FORK_TEST_ARGS)
# ignores invariant tests.
#	@forge test --match-test testCall $(OPT_SEPOLIA_FORK_TEST_ARGS) -vvvv 
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
# Still fails on two tests - sort out tomorrow. 
MUMBAI_SEPOLIA_FORK_ARGS := --fork-url $(MUMBAI_SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS}
MUMBAI_SEPOLIA_FORK_TEST_ARGS := --fork-url $(MUMBAI_SEPOLIA_RPC_URL) 
MUMBAI_SEPOLIA_ARGS := --rpc-url $(MUMBAI_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

mumbaiSepoliaForkTest: 
#	@forge test --match-test testCustomerCanClaimGift $(MUMBAI_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# @forge test $(MUMBAI_SEPOLIA_FORK_TEST_ARGS)  
#	@forge test --no-match-contract ContinueOnRevert $(MUMBAI_SEPOLIA_FORK_TEST_ARGS)
# ignores invariant tests.
	@forge test --match-test testMintingCardsCreatesValidTokenBasedAccounts $(MUMBAI_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# CardsToProgramToGifts // LoyaltyProgramTest // LoyaltyGiftTest // DeployLoyaltyProgramTest
	
mumbaiSepoliaForkDeploy: 
# @forge script script/DeployRegistry.s.sol:DeployRegistry $(MUMBAI_SEPOLIA_FORK_ARGS)
# @forge script script/ComputeRegistryAddress.s.sol:ComputeRegistryAddress $(MUMBAI_SEPOLIA_FORK_ARGS)
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(MUMBAI_SEPOLIA_FORK_ARGS)
#	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(MUMBAI_SEPOLIA_FORK_ARGS)

mumbaiSepoliaDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(MUMBAI_SEPOLIA_ARGS)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(MUMBAI_SEPOLIA_ARGS)


############################################## 
#     Arbitrum Sepolia testnet							 #
##############################################
ARB_SEPOLIA_FORK_ARGS := --fork-url $(ARB_SEPOLIA_RPC_URL) --broadcast --account dev_2 --sender ${DEV2_ADDRESS}
ARB_SEPOLIA_FORK_TEST_ARGS := --fork-url $(ARB_SEPOLIA_RPC_URL) 
ARB_SEPOLIA_ARGS := --rpc-url $(ARB_SEPOLIA_RPC_URL) --account dev_2 --sender ${DEV2_ADDRESS} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

arbSepoliaForkTest: 
#	@forge test --match-test testCustomerCanClaimGift $(ARB_SEPOLIA_FORK_TEST_ARGS) -vvvv 
# @forge test $(ARB_SEPOLIA_FORK_TEST_ARGS)  
	@forge test --match-test testLoyaltyProgramMintsCards $(ARB_SEPOLIA_FORK_TEST_ARGS) -vvvv
# ignores invariant tests. 
#	@forge test --match-test testNameDeployedLoyaltyProgramIsCorrect $(ARB_SEPOLIA_FORK_TEST_ARGS) -vvvv
# CardsToProgramToGifts // LoyaltyProgramTest // LoyaltyGiftTest // DeployLoyaltyProgramTest
	
arbSepoliaForkDeploy: 
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ARB_SEPOLIA_FORK_ARGS)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(ARB_SEPOLIA_FORK_ARGS)

arbSepoliaDeploy:
	@forge script script/DeployLoyaltyProgram.s.sol:DeployLoyaltyProgram $(ARB_SEPOLIA_ARGS)
	@forge script script/DeployLoyaltyGifts.s.sol:DeployMockLoyaltyGifts $(ARB_SEPOLIA_ARGS)

# cast abi-encode "constructor(uint256)" 1000000000000000000000000 -> 0x00000000000000000000000000000000000000000000d3c21bcecceda1000000
# Update with your contract address, constructor arguments and anything else

verify:
	@forge verify-contract --chain-id 11155111 --num-of-optimizations 200 --watch --constructor-args 0x00000000000000000000000000000000000000000000d3c21bcecceda1000000 --etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version v0.8.19+commit.7dd6d404 0x089dc24123e0a27d44282a1ccc2fd815989e3300 src/OurToken.sol:OurToken