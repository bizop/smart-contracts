// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract ChampionNft is ERC721A, Ownable, ReentrancyGuard {

    constructor() ERC721A("THE GAME CHAMPION", "CHAMPION") Ownable() { 

    }

    uint256 nonce = 0;
    uint256 maxSupply = 3333;
    uint256 maxPerAddress = 7;
    uint256 cardsPerPack = 1;
    uint256 totalCardsMinted = 1;
    bool paused = false;

    mapping(address => uint256) public addressMintedBalance;
    mapping(uint256 => Champion) public champion;

    struct Champion {
        uint256 id;
        string class;
        string name;
        uint256 goldPerDay;
        uint256 health;
        uint256 mana;
        uint256 damage;
        uint256 strength;
        uint256 wisdom;
        uint256 spirit;
    }

    // Champion creation
    function mintDeck() public mintCheck() {
        for (uint256 i = 0; i < cardsPerPack; i++) {
            string memory _class = _getClass(_rand(3));
            uint256[6] memory boosts = _getBoosts(_class);
            champion[totalCardsMinted] = Champion({
                id: totalCardsMinted,
                class: _class,
                name: _getName(_rand(17), _rand(18)),
                
                goldPerDay: 100 + _rand(100),

                health: _rand(150) + boosts[0],
                mana: _rand(150) + boosts[1],
                damage: _rand(150) + boosts[2],

                strength: _rand(150) + boosts[3],
                wisdom: _rand(150) + boosts[4],
                spirit: _rand(150) + boosts[5]
            });
            _iterate();
        }
        _mint(cardsPerPack);
    }

    function _mint(uint256 qty) internal {
        _safeMint(msg.sender, qty);
    }

    function _iterate() internal {
        ++addressMintedBalance[msg.sender];
        ++totalCardsMinted;
    }

    // Metadata creation
    function _getClass(uint256 index) internal pure returns (string memory) {
        string[3] memory _classList = ["Warrior", "Mage", "Healer"];
        // string[7] memory _classList = ["Warrior", "Mage", "Cleric", "Rogue", "Druid", "Paladin", "Hunter"];
        return _classList[index];
    }

    function _getName(uint256 index, uint256 index2) internal pure returns (string memory) {
        string[17] memory firstName = ["Johnny", "Jane", "Willow", "Chase", "Becky", "Archie", "Clark", "Bruce", "Kim", "Cole", "Luke", "Johan", "Timothy", "Charlie", "Scout", "Elizabeth", "Crystal"];
        string[18] memory lastName = ["Bane", "Lane", "Bite", "Song", "Roar", "Johnson", "Sky", "Glow", "Bender", "Shadow", "Whisper", "Shout", "Pearl", "Smith", "Peak", "Sanchez", "Sun", "Moon"];
        return string(abi.encodePacked(firstName[index], " ", lastName[index2]));
    }

    function _getBoosts(string memory _class) internal pure returns (uint256[6] memory) {

        uint256 healthBoost;
        uint256 manaBoost;
        uint256 damageBoost;
        uint256 strengthBoost;
        uint256 wisdomBoost;
        uint256 spiritBoost;

        if (keccak256(abi.encodePacked(_class)) == keccak256(abi.encodePacked("Warrior"))) {
            healthBoost = 200;
            manaBoost = 0;
            damageBoost = 200;
            strengthBoost = 200;
            wisdomBoost = 100;
            spiritBoost = 50;
        } else if (keccak256(abi.encodePacked(_class)) == keccak256(abi.encodePacked("Mage"))) {
            healthBoost = 50;
            manaBoost = 200;
            damageBoost = 200;
            strengthBoost = 0;
            wisdomBoost = 200;
            spiritBoost = 100;
        } else if (keccak256(abi.encodePacked(_class)) == keccak256(abi.encodePacked("Healer"))) {
            healthBoost = 150;
            manaBoost = 200;
            damageBoost = 0;
            strengthBoost = 50;
            wisdomBoost = 150;
            spiritBoost = 200;
        }
        
        return [healthBoost, manaBoost, damageBoost, strengthBoost, wisdomBoost, spiritBoost];

    }

    // Utility functions
    function _rand(uint256 _modulus) internal returns (uint) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, nonce))) % _modulus;
    }

    modifier mintCheck() {
        require(!paused, "MINTING IS NOT LIVE");
        require(addressMintedBalance[msg.sender] + cardsPerPack <= maxPerAddress, "LIMIT OF 1 DECK PER ADDRESS");
        require(totalSupply() + cardsPerPack <= maxSupply, "NOT ENOUGH NFTS LEFT TO MINT");
        _;
    }

    // Get player info
    function getName(uint256 tokenId) public view returns (string memory) {
        return champion[tokenId].name;
    }
    function getClass(uint256 tokenId) public view returns (string memory) {
        return champion[tokenId].class;
    }

    // Change player info
    function changeName(uint256 tokenId, string memory _newName) public {
        require(this.ownerOf(tokenId) == msg.sender, "must be account owner to change name");
        champion[tokenId].name = _newName;
    }
    function gainHealth(uint256 tokenId, uint256 _healthGained) public {
        require(this.ownerOf(tokenId) == msg.sender, "must be account owner to change name");
        champion[tokenId].health += _healthGained;
    }

    // Get base vitals
    function getHealth(uint256 tokenId) public view returns (uint256) {
        return champion[tokenId].health;
    }
    function getMana(uint256 tokenId) public view returns (uint256) {
        return champion[tokenId].mana;
    }
    function getDamage(uint256 tokenId) public view returns (uint256) {
        return champion[tokenId].damage;
    }

    // Get base stats
    function getStrength(uint256 tokenId) public view returns (uint256) {
        return champion[tokenId].strength;
    }
    function getWisdom(uint256 tokenId) public view returns (uint256) {
        return champion[tokenId].wisdom;
    }
    function getSpirit(uint256 tokenId) public view returns (uint256) {
        return champion[tokenId].spirit;
    }

    // Get economy info
    function getGoldPerDay(uint256 tokenId) public view returns (uint256) {
        return champion[tokenId].goldPerDay;
    }

    // Inspired by @dom's implementation - MIT license
    // https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code
    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        string memory warriorSvg = '<path d="M426.619 494.929L414.714 548.5V372.905L420.667 461L439.119 423.5L467.69 372.905L479 329.452V397.31L449.833 443.143L426.619 494.929Z" fill="#0C0C0C"/> <path d="M439.119 416.357L422.452 451.476L418.286 374.69L449.833 358.024L462.333 316.357L422.452 333L390.905 356.833L392.69 421.714L379 434.214V195L388 220.5L414.714 249.5L446 271L479 286.595L477.214 319.333L471.857 346.714L463.524 372.905L454 387.19L439.119 416.357Z" fill="#0C0C0C"/> <path d="M323.381 494.929L335.286 555.5L338 467L335.286 372.905L329.333 461L310.881 423.5L282.31 372.905L271 329.452V397.31L300.167 443.143L323.381 494.929Z" fill="#0C0C0C"/> <path d="M310.881 416.357L327.548 451.476L329.333 372.905L300.167 358.024L287.667 316.357L327.548 333.5L359.095 356.833L357.31 421.714L371 434.214V198.5L362 220.5L335.286 249.5L304 271L271 286.595L272.786 319.333L278.143 346.714L286.476 372.905L296 387.19L310.881 416.357Z" fill="#0C0C0C"/>';
        string memory mageSvg = '<path d="M369.5 606.5L354.5 624H350.5L358.5 497L354.5 409L373 411.5L369.5 499.5V606.5Z" fill="#0C0C0C"/> <path d="M366.5 407.5L354.5 404.5L357.5 367L354.5 321H357.5L371.5 334.5L374 404.5L366.5 407.5Z" fill="#0C0C0C"/> <path d="M371.5 327.5L357.5 314.5L353 279.5L325 262L321 227L325 229L347.5 249.5H365L377 240L389.5 223L396.5 201.5L374 163L328 170L381.5 126L402 138L419 154L427 175L429 197.5L419 227L402 251.5L374 274.5L371.5 327.5Z" fill="#0C0C0C"/> <circle cx="358" cy="223.5" r="23" fill="#0C0C0C"/>';
        string memory healerSvg = '<path d="M374.644 500L293.651 434.483L262.086 387.931L243 340.394V311.5L251.319 279.803L273.831 258.128L307.109 250L344.057 252.956L374.644 267.734L383.208 277.586L407.187 263.3L431.412 254.926L460.53 258.128L485.733 271.675L502.127 300.493L508 335.714L502.127 362.808C497.723 371.264 488.278 388.966 485.733 392.118C483.188 395.271 467.871 410.016 460.53 416.995L481.084 392.118L493.563 362.808L498.702 340.394L496.744 315.517L485.733 290.887L471.296 274.877L447.317 267.734L413.794 271.675L392.506 285.468L381.006 300.493C375.704 292.857 364.611 277.586 362.654 277.586C360.696 277.586 346.015 271.018 338.919 267.734L304.907 269.458L281.416 285.468C276.767 294.335 267.469 312.759 267.469 315.517V347.855L272.118 362.808L267.469 350.493V347.855L262.086 330.542V304.926L272.118 282.512L262.086 298.276L255.724 330.542L262.086 359.852L281.416 396.305L304.907 429.064L334.025 460.591L374.644 500Z" fill="#0C0C0C"/> <path d="M413.794 325.369L414.773 303.202H433.125V282.512H454.413V303.202H473.988V325.369H454.413V343.596H433.125L431.412 325.369H413.794Z" fill="#0C0C0C"/>';

        string memory emblem;
        bytes32 hash = keccak256(abi.encodePacked(champion[tokenId].class));

        if (hash == keccak256(abi.encodePacked("Warrior"))) {
            emblem = warriorSvg;
        } else if (hash == keccak256(abi.encodePacked("Mage"))) {
            emblem = mageSvg;
        } else if (hash == keccak256(abi.encodePacked("Healer"))) {
            emblem = healerSvg;
        }

        string[23] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" width="750" height="750" viewBox="0 0 750 750" fill="none"><style>.base { fill: black; font-family: courier, serif; font-weight: bold; font-size: 32px; }</style><rect width="750" height="750" fill="#0C0C0C"/> <rect x="25" y="25" width="700" height="700" fill="#F6F6F6"/> <path d="M665.5 131.5H665.373C664.743 131.5 664.14 131.25 663.695 130.805C663.25 130.36 663 129.757 663 129.128C663 128.464 662.737 127.829 662.268 127.36C661.799 126.891 661.163 126.628 660.5 126.628C659.837 126.628 659.201 126.891 658.732 127.36C658.263 127.829 658 128.464 658 129.128C658 131.083 658.777 132.958 660.159 134.341C661.542 135.723 663.417 136.5 665.373 136.5H665.5V139C665.5 139.663 665.763 140.299 666.232 140.768C666.701 141.237 667.337 141.5 668 141.5C668.663 141.5 669.299 141.237 669.768 140.768C670.237 140.299 670.5 139.663 670.5 139V136.5C672.489 136.5 674.397 135.71 675.803 134.303C677.21 132.897 678 130.989 678 129C678 127.011 677.21 125.103 675.803 123.697C674.397 122.29 672.489 121.5 670.5 121.5V116.5H670.555C671.905 116.5 673 117.595 673 118.945C673 119.608 673.263 120.244 673.732 120.713C674.201 121.182 674.837 121.445 675.5 121.445C676.163 121.445 676.799 121.182 677.268 120.713C677.737 120.244 678 119.608 678 118.945C678 116.97 677.216 115.077 675.819 113.681C674.423 112.284 672.53 111.5 670.555 111.5H670.5V109C670.5 108.337 670.237 107.701 669.768 107.232C669.299 106.763 668.663 106.5 668 106.5C667.337 106.5 666.701 106.763 666.232 107.232C665.763 107.701 665.5 108.337 665.5 109V111.5C664.515 111.5 663.54 111.694 662.63 112.071C661.72 112.448 660.893 113 660.197 113.697C659.5 114.393 658.948 115.22 658.571 116.13C658.194 117.04 658 118.015 658 119C658 119.985 658.194 120.96 658.571 121.87C658.948 122.78 659.5 123.607 660.197 124.303C660.893 125 661.72 125.552 662.63 125.929C663.54 126.306 664.515 126.5 665.5 126.5V131.5ZM670.5 131.5V126.5C671.163 126.5 671.799 126.763 672.268 127.232C672.737 127.701 673 128.337 673 129C673 129.663 672.737 130.299 672.268 130.768C671.799 131.237 671.163 131.5 670.5 131.5ZM665.5 116.5V121.5C664.837 121.5 664.201 121.237 663.732 120.768C663.263 120.299 663 119.663 663 119C663 118.337 663.263 117.701 663.732 117.232C664.201 116.763 664.837 116.5 665.5 116.5V116.5ZM668 149C654.193 149 643 137.807 643 124C643 110.193 654.193 99 668 99C681.807 99 693 110.193 693 124C693 137.807 681.807 149 668 149Z" fill="#0C0C0C"/> <path d="M69.5059 669.166C69.3054 668.958 69.0655 668.793 68.8003 668.679C68.5351 668.565 68.2498 668.505 67.9612 668.502C67.6726 668.5 67.3863 668.555 67.1191 668.664C66.852 668.773 66.6093 668.935 66.4052 669.139C66.2011 669.343 66.0396 669.586 65.9303 669.853C65.821 670.12 65.766 670.406 65.7686 670.695C65.7711 670.984 65.831 671.269 65.945 671.534C66.0589 671.799 66.2245 672.039 66.4321 672.24L69.5059 675.314L63.3561 681.461C62.9482 681.054 62.3951 680.825 61.8185 680.825C61.2418 680.825 60.6888 681.054 60.2812 681.462C59.8736 681.87 59.6447 682.423 59.6449 683C59.6452 683.577 59.8744 684.13 60.2823 684.537L63.3561 687.611C63.7637 688.019 64.3167 688.248 64.8934 688.248C65.47 688.249 66.0231 688.02 66.431 687.612C66.8389 687.204 67.0682 686.651 67.0684 686.075C67.0686 685.498 66.8397 684.945 66.4321 684.537L72.5797 678.387L75.6535 681.461C76.0635 681.857 76.6127 682.076 77.1826 682.071C77.7526 682.066 78.2978 681.838 78.7009 681.435C79.1039 681.032 79.3325 680.486 79.3375 679.916C79.3425 679.346 79.1233 678.797 78.7274 678.387L69.5059 669.166ZM71.0428 667.627L80.2664 676.853L98.7115 658.405L97.1746 650.719L89.4879 649.182L71.0428 667.627Z" fill="#0C0C0C"/> <path d="M672.844 671.031L693 669L672.844 666.969L685.656 651.344L670.031 664.156L668 644L665.969 664.156L650.344 651.344L663.156 666.969L643 669L663.156 671.031L650.344 686.656L665.969 673.844L668 694L670.031 673.844L685.656 686.656L672.844 671.031Z" fill="#0C0C0C"/> <path d="M91.7864 590.81C92.0148 590.704 92.2869 590.755 92.4649 590.933C92.643 591.111 92.6937 591.383 92.5877 591.612L91.2758 594.493L92.5879 597.377C92.692 597.606 92.6436 597.877 92.4649 598.056C92.2863 598.235 92.0153 598.283 91.7855 598.179L88.9019 596.867L86.021 598.178C85.7929 598.284 85.5202 598.234 85.3421 598.056C85.164 597.878 85.114 597.605 85.2197 597.377L86.5313 594.496L85.1691 591.563C85.065 591.333 85.1635 591.112 85.3421 590.933C85.5207 590.755 85.7417 590.656 85.9715 590.76L88.9052 592.122L91.7864 590.81ZM101.22 601.254C103.31 601.257 105.001 602.948 104.999 605.032L105 608.882C104.998 610.965 103.306 612.657 101.224 612.658L58.7762 612.658C56.695 612.658 55.0022 610.965 55 608.882L55.0011 605.032C54.9983 602.948 56.69 601.256 58.7795 601.254H101.22ZM91.7864 605.664H60V608.249H91.7864V605.664ZM72.1143 583.626L76.4386 585.591L80.7624 583.626C81.1074 583.469 81.513 583.543 81.7807 583.81C82.0478 584.077 82.1213 584.483 81.9649 584.828L80 589.152L81.9643 593.476C82.1202 593.821 82.0478 594.228 81.7807 594.495C81.5136 594.762 81.1074 594.834 80.7624 594.678L76.4386 592.714L72.1148 594.678C71.7698 594.834 71.3636 594.762 71.0965 594.495C70.8288 594.227 70.7559 593.82 70.9123 593.476L72.8772 589.152L70.9123 584.828C70.7562 584.483 70.8294 584.077 71.0965 583.81C71.3636 583.543 71.769 583.47 72.1143 583.626Z" fill="#0C0C0C"/> <path d="M691.438 612.75H644.562C643.699 612.75 643 613.449 643 614.312V617.438C643 618.301 643.699 619 644.562 619H691.438C692.301 619 693 618.301 693 617.438V614.312C693 613.449 692.301 612.75 691.438 612.75ZM661.75 606.5L655.5 603.375L661.75 600.25L664.875 594L668 600.25L674.25 603.375L668 606.5L666.438 609.625H686.75L678.312 589.935C677.708 588.528 677.642 586.948 678.127 585.496L683.625 569L665.307 579.468C662.996 580.788 661.167 582.812 660.086 585.244L649.25 609.625H663.312L661.75 606.5ZM668 584.625L669.562 581.5L671.125 584.625L674.25 586.188L671.125 587.75L669.562 590.875L668 587.75L664.875 586.188L668 584.625Z" fill="#0C0C0C"/> <path d="M66.6283 501.081C63.9632 501.473 61.6083 502.795 59.6094 505.021C58.4837 506.275 58.0012 507.071 57.1626 509.108C55.7956 512.36 55.6233 516.407 56.7031 519.833C57.0592 520.967 57.1396 521.142 57.8863 522.599C58.4607 523.732 59.1614 524.582 67.8345 534.74C72.9579 540.744 77.8056 546.41 78.5983 547.327L80.0342 549L90.5453 536.67C96.3235 529.897 101.275 524.029 101.539 523.624C102.619 521.992 103.411 519.941 103.802 517.81C104.066 516.38 104.066 513.722 103.802 512.319C102.814 506.95 99.4825 502.822 95.0828 501.5C92.9576 500.852 91.1426 500.839 89.0864 501.432C87.995 501.742 86.3868 502.525 86.3868 502.741C86.3868 502.822 86.3523 502.835 86.3064 502.795C86.2719 502.741 86.0651 502.849 85.8584 503.038C85.6516 503.226 85.4448 503.375 85.4104 503.375C85.2036 503.375 83.8595 504.764 82.4351 506.464C80.689 508.528 80.1146 509.176 79.9997 509.176C79.9538 509.176 78.851 507.948 77.5529 506.437C74.9452 503.442 74.1641 502.781 72.2801 501.945C70.5226 501.176 68.294 500.839 66.6283 501.081ZM82.8716 515.193C83.0324 515.368 83.0554 515.854 83.0554 518.43V521.452H85.6975C88.1788 521.452 88.3397 521.466 88.4545 521.709C88.6039 522.046 88.6039 528.049 88.4545 528.332C88.3626 528.494 87.8917 528.548 85.732 528.602L83.1129 528.67L83.0784 531.638C83.0554 534.471 83.0439 534.619 82.8142 534.835C82.5959 535.051 82.2858 535.078 80.0227 535.078C77.909 535.078 77.438 535.037 77.2198 534.862C76.967 534.66 76.967 534.606 76.967 531.624V528.602H74.4168C72.2112 528.602 71.8436 528.575 71.6598 528.373C71.476 528.171 71.453 527.887 71.453 525.014C71.453 522.424 71.4875 521.843 71.6254 521.682C71.8666 521.385 73.291 521.263 75.2784 521.358L76.967 521.439V518.417C76.967 515.854 76.99 515.368 77.1508 515.193C77.3002 515.004 77.7252 514.977 80.0112 514.977C82.2972 514.977 82.7223 515.004 82.8716 515.193Z" fill="#0C0C0C"/> <path d="M643 541.602C643 541.602 645.777 510.359 654.109 499L667.995 501.777L665.217 510.359H659.663V530.243H662.44C667.995 521.717 679.492 518.607 686.435 521.717C695.6 525.966 694.767 538.769 686.435 544.435C679.77 548.989 659.663 552.961 643 541.602Z" fill="#0C0C0C"/><text x="55" y="80" class="base">';
        parts[1] = string(abi.encodePacked("#", toString(champion[tokenId].id)));

        parts[2] = '</text><text x="695" y="80" text-anchor="end" class="base">';
        parts[3] = string(abi.encodePacked("'", champion[tokenId].name, "'"));

        parts[4] = '</text><text x="55" y="135" class="base">';
        parts[5] = string(abi.encodePacked(champion[tokenId].class));

        parts[6] = '</text><text x="615" y="135" text-anchor="end" class="base">';
        parts[7] = string(abi.encodePacked(toString(champion[tokenId].goldPerDay)));

        parts[8] = '</text><text x="130" y="535" class="base">';
        parts[9] = string(abi.encodePacked(toString(champion[tokenId].health)));

        parts[10] = '</text><text x="130" y="610" class="base">';
        parts[11] = string(abi.encodePacked(toString(champion[tokenId].mana)));

        parts[12] = '</text><text x="130" y="680" class="base">';
        parts[13] = string(abi.encodePacked(toString(champion[tokenId].damage)));

        parts[14] = '</text><text x="615" y="535" text-anchor="end" class="base">';
        parts[15] = string(abi.encodePacked(toString(champion[tokenId].strength)));

        parts[16] = '</text><text x="615" y="610" text-anchor="end" class="base">';
        parts[17] = string(abi.encodePacked(toString(champion[tokenId].wisdom)));

        parts[18] = '</text><text x="615" y="680" text-anchor="end" class="base">';
        parts[19] = string(abi.encodePacked(toString(champion[tokenId].spirit)));

        parts[20] = '</text>';
        parts[21] = emblem;
        parts[22] = '</svg>';
        

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
        output = string(abi.encodePacked(output, parts[5], parts[6], parts[7], parts[8], parts[9]));
        output = string(abi.encodePacked(output, parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Champion #', toString(tokenId), '", "description": "The_Game is a randomized adventurer game generated and stored on chain. Designed to be LoFi and expandable. Feel free to use the_game in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
