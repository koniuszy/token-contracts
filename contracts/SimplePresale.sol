// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// missing autoclosing and sending money back

// potential approach is to expose a function 'revert' for users so after a specyfic time they could send back the alloacted money
// the gas price should be charged from the allocated money
// maybe revert funciton could be accessable for everybody and it would revert money to everyone on call
// so we could avoid instructing people how to get their money back

contract SimplePresale is Ownable, Pausable {
  using Address for address;
  using SafeMath for uint256;

  uint256 public constant MIN_AMOUNT = 0.2 ether;
  uint256 public constant MAX_AMOUNT = 5 ether;
  uint256 public constant HARD_CAP = 900 ether;
  uint256 public constant SOFT_CAP = 600 ether;

  uint256 public raisedAmount;
  mapping(address => uint256) private _allocations;

  constructor() {}

  receive() external payable {
    allocate();
  }

  fallback() external payable {
    allocate();
  }

  function allocate() public payable whenNotPaused {
    require(raisedAmount < HARD_CAP, "Target raised. Not accepting any more payments");
    require(msg.value != 0, "Sent value cannot be 0!");
    require(msg.value >= MIN_AMOUNT && msg.value <= MAX_AMOUNT, "Sent value must be within MIN<>MAX amount");
    require(raisedAmount + msg.value <= HARD_CAP, "Sent value goes over max target. Please try sending lower amount");
    require(
      _allocations[msg.sender] + msg.value <= MAX_AMOUNT,
      "Sent value goes over max target. Please try sending lower amount"
    );

    raisedAmount = raisedAmount.add(msg.value);
    _allocations[msg.sender] = _allocations[msg.sender].add(msg.value);
  }

  function withdraw() external onlyOwner {
    require(raisedAmount >= SOFT_CAP || paused(), "Cannot withdraw yet");

    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function allocation(address participant) public view returns (uint256) {
    return _allocations[participant];
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}
