// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.4;
import "./Nft.sol";
import "./Token.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Vault is Ownable, IERC721Receiver {

    using Strings for uint256;

    uint256[] public scores;
    uint256[] public boosts;
    uint256 public totalStaked;
    bool public boostsLive = false;
    address contractOwner;

    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }

    event NftStaked(address owner, uint256 tokenId, uint256 value);
    event NftUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    Nft nft;
    Token token;

    mapping(uint256 => Stake) public vault; 

    constructor(Nft _nft, Token _token) { 
        nft = _nft;
        token = _token;
        contractOwner = msg.sender;
    }

    function setScores(uint256[] calldata tokenScores) public onlyOwner {
        delete scores;
        scores = tokenScores;
    }

    function resetScore(uint256 tokenId, uint256 newScore) public onlyOwner {
        uint256 tokenIndex = tokenId - 1;
        scores[tokenIndex] = newScore;
    }

    function getScoreIndex() public view onlyOwner returns (uint256) {
        return scores.length;
    }

    function addToScores(uint256[] calldata tokenScores) public onlyOwner {
        for (uint i = 0; i < tokenScores.length; i++) {
            uint256 tokenScore = tokenScores[i];
            scores.push(tokenScore);
        }
    }

    function getScore(uint256 tokenId) public view returns (uint256) {
        uint256 tokenIndex = tokenId - 1;
        uint256 tokenScore = scores[tokenIndex];
        return tokenScore;
    }

    function setBoosts(uint256[] calldata tokenBoosts) public onlyOwner {
        delete boosts;
        boosts = tokenBoosts;
    }

    function resetBoost(uint256 tokenId, uint256 newBoost) public onlyOwner {
        uint256 tokenIndex = tokenId - 1;
        boosts[tokenIndex] = newBoost;
    }

    function getBoostIndex() public view onlyOwner returns (uint256) {
        return boosts.length;
    }

    function addToBoosts(uint256[] calldata tokenBoosts) public onlyOwner {
        for (uint i = 0; i < tokenBoosts.length; i++) {
            uint256 tokenBoost = tokenBoosts[i];
            boosts.push(tokenBoost);
        }
    }

    function getBoost(uint256 tokenId) public view returns (uint256) {
        uint256 tokenIndex = tokenId - 1;
        uint256 tokenBoost = boosts[tokenIndex];
        return tokenBoost;
    }

    function setBoostsLive(bool _boostsLive) public onlyOwner {
        boostsLive = _boostsLive;
    }
    
    function moveToVault(uint256[] calldata tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            nft.transferFrom(msg.sender, address(this), tokenId);
            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
            emit NftStaked(msg.sender, tokenId, block.timestamp);
        }
        totalStaked += tokenIds.length;
    }

    function moveFromVault(uint256[] calldata tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender || contractOwner == msg.sender , "not an owner or not staked");
            _claim(tokenId);
            nft.transferFrom(address(this), staked.owner, tokenId);
            emit NftUnstaked(staked.owner, tokenId, block.timestamp);
            delete vault[tokenId];
        }
        totalStaked -= tokenIds.length;
    }

    function _claim(uint256 tokenId) internal {
        uint256[4] memory earned = _earningInfo(tokenId);
        if (earned[0] > 0) {
            Stake memory staked = vault[tokenId];
            emit Claimed(staked.owner, earned[0]);
            token.mint(staked.owner, earned[0]);
        }
    }

    function _earningInfo(uint256 tokenId) internal view returns (uint256[4] memory info) {
        uint256 totalBlockTime;
        uint256 nftScore;
        uint256 earned;

        Stake memory staked = vault[tokenId];

        uint256 stakedAt = staked.timestamp;
                    
        if(stakedAt == 0){
            earned = 0;
        } else {
            if(boostsLive == true){
                nftScore = _boostMultiplier(tokenId);
            } else {
                nftScore = getScore(tokenId);
            }
            earned += 1 ether * nftScore * (block.timestamp - stakedAt) / 1 days;
            totalBlockTime += block.timestamp - stakedAt;
        }

        uint256 earnRatePerDay = nftScore * 1 ether;
        uint256 earnRatePerSecond = earnRatePerDay / 1 days;

        return [earned, earnRatePerSecond, earnRatePerDay, totalBlockTime];
    }

    function claim(uint256[] calldata tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender, "not an owner or not staked");
            uint256[4] memory earned = _earningInfo(tokenId);
            if (earned[0] > 0) {
                vault[tokenId] = Stake({
                    owner: staked.owner,
                    tokenId: uint24(tokenId),
                    timestamp: uint48(block.timestamp)
                });
                emit Claimed(staked.owner, earned[0]);
                token.mint(staked.owner, earned[0]);
            }
        }
    }

    function earningInfo(uint256[] calldata tokenIds) public view returns (uint256[4] memory info) {
        uint256 totalBlockTime;
        uint256 totalNftScore;
        uint256 totalEarned;

        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 nftScore;
            uint256 earned;

            Stake memory staked = vault[tokenId];

            uint256 stakedAt = staked.timestamp;
                        
            if(stakedAt == 0){
                earned = 0;
            } else {
                if(boostsLive == true){
                    nftScore = _boostMultiplier(tokenId);
                } else {
                    nftScore = getScore(tokenId);
                }
                
                earned += 1 ether * nftScore * (block.timestamp - stakedAt) / 1 days;
                totalBlockTime += block.timestamp - stakedAt;
                totalNftScore += nftScore;
                totalEarned += earned;
            }

        }

        uint256 totalEarnRatePerDay = totalNftScore * 1 ether;
        uint256 totalEarnRatePerSecond = totalEarnRatePerDay / 1 days;
        
        return [totalEarned, totalEarnRatePerSecond, totalEarnRatePerDay, totalBlockTime];
    }

    function _boostMultiplier(uint256 tokenId) public view returns (uint256) {
        Stake memory staked = vault[tokenId];
        uint256 finalScore;
        address tokenOwner = staked.owner;
        address deadAddy =  0x0000000000000000000000000000000000000000;
        if(balanceOf(tokenOwner) >= 3 && tokenOwner != deadAddy){
            uint256 tokenIndex = tokenId - 1;
            uint256 tokenScore = scores[tokenIndex];
            if(boosts[tokenIndex] > 0){
                uint256 tokenBoost = tokenScore / (100 / boosts[tokenIndex]);
                finalScore = tokenScore + tokenBoost;
            } else {
                finalScore = tokenScore;
            }
            return finalScore;
        } else {
            uint256 tokenIndex = tokenId - 1;
            finalScore = scores[tokenIndex];
            return finalScore;
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = nft.totalSupply();
        for(uint i = 1; i <= supply; i++) {
            if (vault[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    function ownerOfStaked(uint256 tokenId) public view returns (address) {
        Stake memory staked = vault[tokenId];
        address tokenOwner = staked.owner;
        return tokenOwner;
    }

    function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {
        uint256 supply = nft.totalSupply();
        uint256[] memory tmp = new uint256[](supply);
        uint256 index = 0;
        for(uint tokenId = 1; tokenId <= supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index +=1;
            }
        }
        uint256[] memory tokens = new uint256[](index);
        for(uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }
        return tokens;
    }

    function onERC721Received(address, address from, uint256, bytes calldata) external view override returns (bytes4) {
        require(from == address(this), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

}
