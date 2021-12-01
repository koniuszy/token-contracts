// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock is Ownable {
  using SafeERC20 for IERC20;

  IERC20 public token;
  uint256[] public withdrawTimeFrames;
  uint256[] public withdrawPercentagesFrames;
  address[] public beneficiaryAdresses;
  mapping(address => uint256) _beneficiaries;
  mapping(address => uint256) _initialBeneficiares;

  constructor(uint256[] memory withdrawTimeFrames_, uint256[] memory withdrawPercentagesFrames_) {
    require(withdrawTimeFrames_.length <= 10, "TokenTimelock: you can set max 10 time frames");
    require(
      withdrawTimeFrames_.length == withdrawPercentagesFrames_.length,
      "TokenTimelock: relaeseTimeFrames should have as many items as withdrawPercentagesFrames_"
    );
    uint256 sum = 0;
    for (uint256 i = 0; i < withdrawTimeFrames_.length; ++i) {
      require(withdrawTimeFrames_[i] > block.timestamp, "TokenTimelock: withdraw time is before current time");
      require(withdrawPercentagesFrames_[i] > 0, "TokenTimelock: percantage value is less than 0");
      require(withdrawPercentagesFrames_[i] > 100, "TokenTimelock: percantage value is greater than 100");
      sum += withdrawPercentagesFrames_[i];
    }
    require(sum == 100, "TokenTimelock: sum of withdrawPercentagesFrames_ does not equal 100");

    withdrawTimeFrames = withdrawTimeFrames_;
    withdrawPercentagesFrames = withdrawPercentagesFrames_;
  }

  function setToken(IERC20 token_) external onlyOwner {
    token = token_;
  }

  function addBeneficiaries(address[] memory beneficiaryAddresses_, uint256[] memory balances_) external onlyOwner {
    require(
      beneficiaryAddresses_.length == balances_.length,
      "TokenVesting: Beneficiaries and amounts must have the same length"
    );

    for (uint256 i = 0; i < beneficiaryAddresses_.length; ++i) {
      _beneficiaries[beneficiaryAddresses_[i]] = balances_[i];
      _initialBeneficiares[beneficiaryAddresses_[i]] = balances_[i];
      beneficiaryAdresses.push(beneficiaryAddresses_[i]);
    }
  }

  function beneficiaryBalance(address beneficiary_) external view returns (uint256) {
    return _beneficiaries[beneficiary_];
  }

  function beneficiaryInitialBalance(address beneficiary_) external view returns (uint256) {
    return _initialBeneficiares[beneficiary_];
  }

  function beneficiaryAvaibleTokensToWithdraw(address beneficiary_) public view returns (uint256) {
    require(_beneficiaries[beneficiary_] > 0, "TokenTimelock: your balance is 0");
    uint256 _avaiblePercentages = 0;
    for (uint256 i = 0; i < withdrawTimeFrames.length; ++i) {
      if (withdrawTimeFrames[i] <= block.timestamp) {
        _avaiblePercentages += withdrawPercentagesFrames[i];
      }
    }
    require(_avaiblePercentages > 0, "TokenTimelock: current time is before withdraw time");

    uint256 _withdrawnAmount = _initialBeneficiares[beneficiary_] - _beneficiaries[beneficiary_];
    uint256 _avaibleAmount = SafeMath.div(SafeMath.mul(_initialBeneficiares[beneficiary_], 100), _avaiblePercentages);
    require(_avaibleAmount > 0, "TokenTimelock: nothing to withdraw");

    return SafeMath.sub(_avaibleAmount, _withdrawnAmount);
  }

  function withdraw(address beneficiary_) external {
    require(token.balanceOf(address(this)) > 0, "TokenTimelock: no tokens on the vesting contract to withdraw");
    require(_beneficiaries[beneficiary_] > 0, "TokenTimelock: no tokens assigned to the beneficiary");

    uint256 amount = beneficiaryAvaibleTokensToWithdraw(beneficiary_);
    _beneficiaries[beneficiary_] = 0;
    token.safeTransfer(beneficiary_, amount);
  }
}
