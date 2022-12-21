// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract StakingNFT is ERC721 {
   using Counters for Counters.Counter;
   Counters.Counter private tokenId;

   constructor(
      string memory name_,
      string memory symbol_
   ) ERC721(name_, symbol_) {}

   function mintNFT(uint256 amount_) external {
      require (amount_ > 0, 'wrong amount');
      for (uint256 i = 0; i < amount_; i ++) {
         _safeMint(msg.sender, tokenId.current());
         tokenId.increment();
      }
   }
}