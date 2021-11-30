// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SimplePresale is Ownable, Pausable {
  using Address for address;
  using SafeMath for uint256;

  uint256 public constant MIN_AMOUNT = 0.2 ether;
  uint256 public constant MAX_AMOUNT = 5 ether;
  uint256 public constant TARGET_AMOUNT = 900 ether;

  uint256 private _raisedAmount;
  mapping(address => uint256) private _allocations;

  constructor() {}

  receive() external payable {
    allocate();
  }

  function allocate() public payable whenNotPaused {
    require(_raisedAmount < TARGET_AMOUNT, "Target raised. Not accepting any more payments");
    require(msg.value != 0, "Sent value cannot be 0!");
    require(msg.value >= MIN_AMOUNT && msg.value <= MAX_AMOUNT, "Sent value must be within MIN<>MAX amount");
    require(
      _raisedAmount + msg.value <= TARGET_AMOUNT,
      "Sent value goes over max target. Please try sending lower amount"
    );
    require(
      _allocations[msg.sender] + msg.value <= MAX_AMOUNT,
      "Sent value goes over max target. Please try sending lower amount"
    );

    _raisedAmount = _raisedAmount.add(msg.value);
    _allocations[msg.sender] = _allocations[msg.sender].add(msg.value);
  }

  function withdraw() external onlyOwner {
    require(_raisedAmount >= TARGET_AMOUNT || paused(), "Cannot withdraw yet");

    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function allocation(address participant) public view returns (uint256) {
    return _allocations[participant];
  }

  function pause() external whenNotPaused onlyOwner {
    super._pause();
  }

  function unpause() external whenPaused onlyOwner {
    super._unpause();
  }

  function raisedAmount() public view returns (uint256) {
    return _raisedAmount;
  }
}
