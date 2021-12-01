// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title Token
 * @dev BEP20 compatible token.
 */
contract Token is ERC20Burnable, Ownable {
  /**
   * @dev Mints all tokens to deployer
   * @param amount_ Initial supply
   * @param name_ Token name.
   * @param symbol_ Token symbol.
   */
  constructor(
    uint256 amount_,
    string memory name_,
    string memory symbol_
  ) ERC20(name_, symbol_) {
    _mint(_msgSender(), amount_);
  }

  /**
   * @dev Returns the address of the current owner.
   *
   * IMPORTANT: This method is required to be able to transfer tokens directly between their Binance Chain
   * and Binance Smart Chain. More on this issue can be found in:
   * https://github.com/binance-chain/BEPs/blob/master/BEP20.md#5116-getowner
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  function decimals() public pure override returns (uint8) {
    return 4;
  }
}
