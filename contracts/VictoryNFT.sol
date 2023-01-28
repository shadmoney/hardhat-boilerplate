pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/SafeERC721.sol";

contract VictoryNFT is SafeERC721 {
    string public name = "Proof of Victory";
    string public symbol = "POV";

    mapping(uint256 => struct Victory) public tokenIdToVictory;
    struct Victory {
        string gameName;
        string winnerUsername;
        uint256 timestamp;
    }

    constructor() public {
        _mint(msg.sender, 1, "Proof of Victory");
        tokenIdToVictory[1].gameName = "Game 1";
        tokenIdToVictory[1].winnerUsername = "player1";
        tokenIdToVictory[1].timestamp = block.timestamp;
    }

   function _mint(address to, uint256 tokenId, string memory tokenUri) internal virtual {
        require(msg.sender == msg.sender);
        _mint(msg.sender, _totalSupply() + 1, "POV");
        tokenIdToVictory[_totalSupply()].gameName = _gameName;
        tokenIdToVictory[_totalSupply()].winnerUsername = _winnerUsername;
        tokenIdToVictory[_totalSupply()].timestamp = block.timestamp;
    }

    function getVictory(uint256 _tokenId) public view returns (string memory, string memory, uint256) {
        return (tokenIdToVictory[_tokenId].gameName, tokenIdToVictory[_tokenId].winnerUsername, tokenIdToVictory[_tokenId].timestamp);
    }
}
