// SPDX-License-Identifier: MIT
// OneSheepsWorld NFT - v1.0
// compiled 0.8.18+commit.87f61d96
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OneSheepsWorld is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public allowListCost = 0.1 ether;
    uint256 public cost = 0.1 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10;
    bool public revealed = false;
    string public notRevealedUri;

    bool public publicMintOpen = false;
    bool public allowListMintOpen = false;
    mapping(address => bool) public allowList;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function allowListMint(uint256 _mintAmount) public payable whenNotPaused {
        uint256 supply = totalSupply();
        require(allowListMintOpen, "Allowlist mint is not currently open.");
        
        require(_mintAmount > 0, "You must mint more than 0.");
        require(_mintAmount <= maxMintAmount, "You must mint less than or equal to the maxMintAmount.");
        require(supply + _mintAmount <= maxSupply, "Contract is sold out, all NFT's have been minted.");

        if (msg.sender != owner()) {
            refundIfOver(allowListCost * _mintAmount);
            require(allowList[msg.sender], "You are not on the allow list");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function publicMint(uint256 _mintAmount) public payable whenNotPaused {
        uint256 supply = totalSupply();
        require(publicMintOpen, "Public mint is not currently open.");
        require(_mintAmount > 0, "You must mint more than 0.");
        require(_mintAmount <= maxMintAmount, "You must mint less than or equal to the maxMintAmount.");
        require(supply + _mintAmount <= maxSupply, "Contract is sold out, all NFT's have been minted.");

        if (msg.sender != owner()) {
            refundIfOver(cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    //only owner

    function editMintWindows(
        bool _publicMintOpen,
        bool _allowListMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for(uint256 i = 0; i < addresses.length; i++){
            allowList[addresses[i]] = true;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function reveal() external onlyOwner {
        revealed = true;
    }
    
    function setCost(uint256 _newCost, uint256 _newCostAllowList) external onlyOwner {
        cost = _newCost;
        allowListCost = _newCostAllowList;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

     function withdraw(address _addr) external onlyOwner {
        uint256 balalnce = address(this).balance;
        payable(_addr).transfer(balalnce);
    }
}

