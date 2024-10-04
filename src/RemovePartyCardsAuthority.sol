pragma solidity ^0.8.20;

import "./PartyGovernanceNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RemovePartyCardsAuthority is Ownable {
    PartyGovernanceNFT public partyGovernanceNFT;

    event PartyCardRemoved(uint256 tokenId);

    constructor(address _partyGovernanceNFT) Ownable(msg.sender) {
        partyGovernanceNFT = PartyGovernanceNFT(_partyGovernanceNFT);
    }

    /**
     * @dev Removes a party card by burning the corresponding NFT.
     * @param tokenId The ID of the token to be removed.
     */
    function removePartyCard(uint256 tokenId) external onlyOwner {
        partyGovernanceNFT.burn(tokenId);
        emit PartyCardRemoved(tokenId);
    }

    /**
     * @dev Removes multiple party cards by burning the corresponding NFTs.
     * @param tokenIds An array of token IDs to be removed.
     */
    function removeMultiplePartyCards(
        uint256[] calldata tokenIds
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            partyGovernanceNFT.burn(tokenIds[i]);
            emit PartyCardRemoved(tokenIds[i]);
        }
    }

    /**
     * @dev Updates the PartyGovernanceNFT contract address.
     * @param _newPartyGovernanceNFT The address of the new PartyGovernanceNFT contract.
     */
    function updatePartyGovernanceNFT(
        address _newPartyGovernanceNFT
    ) external onlyOwner {
        require(_newPartyGovernanceNFT != address(0), "Invalid address");
        partyGovernanceNFT = PartyGovernanceNFT(_newPartyGovernanceNFT);
    }
}
