// SPDX-License-Identifier: MIT LICENSE
// Hypothetical on-chain NFT based proposal & voting mechanism. Likely too gas hungry for most L1 projects 

pragma solidity 0.8.4;
import "./Nft.sol";

contract NftOnChainVoting {

    Nft nft;

    constructor(Nft _nft) { 
        nft = _nft;
    }

    mapping(uint256 => Proposals) public proposals;

    uint256 public currentCip = 0;

    struct Proposals {
        uint256 cip;
        bool isActive;
        uint256 endDate;
        uint256 votes;
        int256 sway;
        string name;
        string description;
        string finalResult;
    }

    function createProposal(string memory _name, string memory _description) public {
        require(nft.balanceOf(msg.sender) > 0, "Must be a holder to propose");
        proposals[currentCip] = Proposals({
            cip: currentCip,
            isActive: true,
            endDate: block.timestamp + 1 minutes,
            votes: 0,
            sway: 0,
            name: _name,
            description: _description,
            finalResult: ""
        });
        ++currentCip;
    }

    // 1 = For, 0 = Against
    function castVote(uint256 _cip, uint256 _ballot) public { 
        require(nft.balanceOf(msg.sender) > 0, "Must be a holder to vote");
        require(proposals[_cip].isActive == true, "Proposal must be active to vote");
        require(_ballot == 0 || _ballot == 1, "Ballot must be either 1 (For) or 0 (Against)");
        if(_ballot == 0) {
            proposals[_cip].sway -= 1;
            proposals[_cip].votes += 1;
        } else if(_ballot == 1) {
            proposals[_cip].sway += 1;
            proposals[_cip].votes += 1;
        }
    }

    function closeVote(uint256 _cip) public {
        string memory _result;
        if(proposals[_cip].sway > 0) {
            _result = "Passed";
        } else if(proposals[_cip].sway < 0) {
            _result = "Not Passed";
        } else {
            _result = "Tie";
        }
        proposals[_cip].finalResult = _result;
        proposals[_cip].isActive = false;
    }

}
