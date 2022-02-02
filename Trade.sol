// SPDX-License-Identifier: MIT LICENSE

// This contract shows a hypothetical example of an escrow type service. Not audited, use at your own risk.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Token is ERC721Enumerable {

    constructor() ERC721("Trade Token", "TTX") {
        _safeMint(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 1);
        _safeMint(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 2);
    }

}

contract Trade is IERC721Receiver {

    // pass the token contract address here to reference
    constructor(Token _token) { 
        token = _token;
    }

    // reference to the NFT contract
    Token token;

    using Strings for uint256;

    struct Escrow {
        uint24 proposerToken;
        uint24 accepterToken;
        uint48 timestamp;
        address proposer;
        address accepter;
    }

    // maps proposerToken to escrow
    mapping(uint256 => Escrow) public escrow; 

    function proposeTrade(uint256 proposerToken, uint256 accepterToken) public {
        address accepter = token.ownerOf(accepterToken);
        token.transferFrom(msg.sender, address(this), proposerToken);
        escrow[proposerToken] = Escrow({
            proposerToken: uint24(proposerToken),
            accepterToken: uint24(accepterToken),
            proposer: msg.sender,
            accepter: address(accepter),
            timestamp: uint48(block.timestamp)
        });
    }

    function _finalizeTrade(uint256 proposerToken, address accepter) internal {
        Escrow memory escrowed = escrow[proposerToken];
        uint256 accepterToken = escrowed.accepterToken;
        address proposer = escrowed.proposer;
        token.transferFrom(address(this), accepter, proposerToken);
        token.transferFrom(accepter, proposer, accepterToken);
        delete escrow[proposerToken];
    }

    function acceptTrade(uint256 proposerToken) public {
        _finalizeTrade(proposerToken, msg.sender);
    }

    function cancelTrade(uint256 proposerToken) public {
        Escrow memory escrowed = escrow[proposerToken];
        address accepter = escrowed.accepter;
        address proposer = escrowed.proposer;
        require(msg.sender == proposer || msg.sender == accepter, "not approved to make that decision");
        token.transferFrom(address(this), proposer, proposerToken);
        delete escrow[proposerToken];
    }

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        require(from != address(0x0));
        return IERC721Receiver.onERC721Received.selector;
    }

}
