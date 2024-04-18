// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface Interface {
    error LoyaltyGift__LoyaltyProgramNotRecognised(address loyaltyToken);
    error LoyaltyGift__NftNotOwnedByloyaltyCard(address loyaltyToken);
    error LoyaltyGift__RequirementsNotMet(address loyaltyToken, uint256 loyaltyGiftId);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event LoyaltyGiftDeployed(address indexed issuer);
    event TransferBatch(
        address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values
    );
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);
    function getCost(uint256 index) external view returns (uint256);
    function getHasAdditionalRequirements(uint256 index) external view returns (uint256);
    function getIsClaimable(uint256 index) external view returns (uint256);
    function getIsVoucher(uint256 index) external view returns (uint256);
    function getNumberOfGifts() external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function mintLoyaltyVouchers(uint256[] memory loyaltyGiftIds, uint256[] memory numberOfVouchers) external;
    function requirementsLoyaltyGiftMet(address loyaltyCard, uint256 loyaltyGiftId, uint256 loyaltyPoints)
        external
        returns (bool success);
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
