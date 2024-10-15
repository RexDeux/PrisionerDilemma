// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Import OpenZeppelin's ERC20 contract from GitHub
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/access/Ownable.sol";

contract PrisonerDilemmaCoin is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10**18; // 10 million tokens

    constructor() ERC20("PrisonerDilemmaCoin<", "PDC") {
        _mint(msg.sender, MAX_SUPPLY); // Mint all tokens to contract owner initially
    }

    // Allows the owner to mint additional tokens (optional, if needed for game incentives)
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, amount);
    }

    // Players can burn tokens (e.g., as part of game penalties)
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
