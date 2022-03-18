//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFTMock is ERC721 {
    uint256 public tokenCounter = 1;

    constructor() payable ERC721('Token', 'TOK') {}

    function mint() external payable {
        _safeMint(msg.sender, tokenCounter);
        tokenCounter++;
    }
}
