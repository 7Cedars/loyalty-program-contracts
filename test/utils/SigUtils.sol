// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

// This contract is based on foundry book example: https://book.getfoundry.sh/tutorials/testing-eip712
contract SigUtils {
    address internal loyaltyProgramAddress;

    constructor(address _loyaltyProgramAddress) {
        loyaltyProgramAddress = _loyaltyProgramAddress;
    }

    bytes32 internal DOMAIN_SEPARATOR = hashDomain(EIP712Domain({
            name: "Loyalty Program",
            version: "1",
            chainId: 31337,
            verifyingContract: loyaltyProgramAddress
        }));

    // // keccak256("RequestGift(address from,address to,string gift,string cost,uint256 nonce)");
    // bytes32 public constant REQUEST_GIFT__TYPEHASH =
    //     0xcdc9dd19ef04fac55ad1978d894ba812ceb6c6198bef5842a2da30174fd28aba;

    // EIP712 domain separator
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract; 
    }

    // RequestGift message struct
    struct RequestGift {
        address from;
        address to;
        string gift;
        string cost;
        uint256 nonce;
    }

    // Redeem token message struct
    struct RedeemVoucher {
        address from;
        address to;
        string voucher;
        uint256 nonce;
    }

    function hashDomain(EIP712Domain memory domain) private pure returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(domain.name)),
            keccak256(bytes(domain.version)),
            domain.chainId,
            domain.verifyingContract
        ));
    }

    // computes the hash of a permit
    function getHashRequestGift(RequestGift memory _requestGift)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(bytes("RequestGift(address from,address to,string gift,string cost,uint256 nonce)")),
                    _requestGift.from,
                    _requestGift.to,
                    keccak256(bytes(_requestGift.gift)),
                    keccak256(bytes(_requestGift.cost)),
                    _requestGift.nonce
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(RequestGift memory _requestGift)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    getHashRequestGift(_requestGift)
                )
            );
    }
}