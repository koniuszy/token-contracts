// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// >>>>>>>>>> !IMPORTANT! <<<<<<<<<<<
// this is an invalid token sale contract which requrie more gas with each allocation, why though ?
// i managed to fix the above by performing checks on mapping instead of array

import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @dev Allows to create allocations for token sale.
 */
contract InvalidPresale is Ownable {
  uint256 constant EVERYONE_ALLOCATION_DELAY = 1 hours;
  uint256 constant OWNER_PAYOUT_DELAY = 30 days;

  uint256 private _closingAllocationsRemainder;
  uint256 private _minimumAllocation;
  uint256 private _maximumAllocation;
  uint256 private _totalAllocationsLimit;
  uint256 private _totalAllocated;
  uint256 private _saleStart;
  bool private _isEveryoneAllowedToParticipateAfterDelay;
  bool private _wasClosed;
  bool private _wasStarted;
  mapping(address => uint256) private _allocations;
  mapping(address => bool) private _allowedParticipants;
  address[] _allowedParticipantList;

  address[] private _participants;

  event SaleStarted();
  event SaleClosed();
  event Allocated(address indexed participant, uint256 allocation);

  /**
   * @dev Initializes sale contract with minimum and maximum amount that can be allocated and total allocation limit.
   * @param _initialAllowedParticipants List of addresses allowed to participate.
   * @param _initialIsEveryoneAllowedToParticipateAfterDelayValue Decides if everyone should be allowed to participate after delay.
   */
  constructor(address[] memory _initialAllowedParticipants, bool _initialIsEveryoneAllowedToParticipateAfterDelayValue)
  {
    _closingAllocationsRemainder = 0;
    _minimumAllocation = 0;
    _maximumAllocation = 0;
    _totalAllocationsLimit = 0;
    _totalAllocated = 0;
    _saleStart = 0;
    _isEveryoneAllowedToParticipateAfterDelay = _initialIsEveryoneAllowedToParticipateAfterDelayValue;
    _wasClosed = false;
    _wasStarted = false;

    for (uint256 i = 0; i < _initialAllowedParticipants.length; ++i) {
      address _selectedAddress = _initialAllowedParticipants[i];
      _allowedParticipants[_selectedAddress] = true;
    }

    _allowedParticipantList = _initialAllowedParticipants;
  }

  /**
   * @dev Setups and starts the sale.
   * @param minimumAllocationValue Minimum allocation value.
   * @param maximumAllocationValue Maximum allocation value.
   * @param totalAllocationsLimitValue Total allocations limit.
   * @param closingAllocationsRemainderValue Remaining amount of allocations allowing to close sale before reaching total allocations limit.
   */
  function startSale(
    uint256 minimumAllocationValue,
    uint256 maximumAllocationValue,
    uint256 totalAllocationsLimitValue,
    uint256 closingAllocationsRemainderValue
  ) public onlyOwner {
    require(!_wasStarted, "PresalePublic: Sale was already started");

    _closingAllocationsRemainder = closingAllocationsRemainderValue;
    _minimumAllocation = minimumAllocationValue;
    _maximumAllocation = maximumAllocationValue;
    _totalAllocationsLimit = totalAllocationsLimitValue;
    _saleStart = block.timestamp;
    _wasStarted = true;

    emit SaleStarted();
  }

  /**
   * @dev Allows to allocate currency for the sale.
   */
  function allocate() public payable {
    require(wasStarted(), "PresalePublic: Cannot allocate yet");
    require(areAllocationsAccepted(), "PresalePublic: Cannot allocate anymore");
    require((msg.value >= _minimumAllocation), "PresalePublic: Allocation is too small");
    require(((msg.value + _allocations[msg.sender]) <= _maximumAllocation), "PresalePublic: Allocation is too big");
    require(canAllocate(msg.sender), "PresalePublic: Not allowed to participate");

    _totalAllocated += msg.value;

    if (_allocations[msg.sender] == 0) {
      _participants.push(msg.sender);
    }

    _allocations[msg.sender] += msg.value;

    emit Allocated(msg.sender, msg.value);
  }

  /**
   * @dev Allows the owner to close sale and payout all currency.
   */
  function closeSale() public onlyOwner {
    require(canCloseSale(), "PresalePublic: Cannot payout yet");

    payable(owner()).transfer(address(this).balance);

    _wasClosed = true;

    emit SaleClosed();
  }

  /**
   * @dev Extend the allowed participants list.
   */
  function addAllowedParticipants(address[] memory participantsValue) public onlyOwner {
    require(areAllocationsAccepted(), "PresalePublic: Allocations were already closed");

    for (uint256 i = 0; i < participantsValue.length; ++i) {
      address _selectedAddress = participantsValue[i];
      if (!_allowedParticipants[_selectedAddress]) {
        _allowedParticipantList.push(_selectedAddress);
      }
      _allowedParticipants[_selectedAddress] = true;
    }
  }

  /**
   * @dev Returns amount allocated from given address.
   * @param participant Address to check.
   */
  function allocation(address participant) public view returns (uint256) {
    return _allocations[participant];
  }

  /**
   * @dev Return the allowed participants list.
   */
  function allowedParticipants() public view returns (address[] memory) {
    return _allowedParticipantList;
  }

  /**
   * @dev Checks if allocations are still accepted.
   */
  function areAllocationsAccepted() public view returns (bool) {
    return (isActive() && (_totalAllocationsLimit - _totalAllocated) >= _minimumAllocation);
  }

  /**
   * @dev Checks if given address can still allocate.
   */
  function canAllocate(address participant) public view returns (bool) {
    if (!areAllocationsAccepted() || !isAllowedToParticipate(participant)) {
      return false;
    }

    return ((_allocations[participant] + _minimumAllocation) <= _maximumAllocation);
  }

  /**
   * @dev Checks if owner can close sale and payout the currency.
   */
  function canCloseSale() public view returns (bool) {
    return (isActive() &&
      (!areAllocationsAccepted() ||
        _closingAllocationsRemainder >= (_totalAllocationsLimit - _totalAllocated) ||
        block.timestamp >= (_saleStart + OWNER_PAYOUT_DELAY)));
  }

  /**
   * @dev Returns remaining amount of allocations allowing to close sale before reaching total allocations limit.
   */
  function closingAllocationsRemainder() public view returns (uint256) {
    return _closingAllocationsRemainder;
  }

  /**
   * @dev Checks if given address is allowed to participate.
   */
  function isAllowedToParticipate(address participant) public view returns (bool) {
    if (
      _isEveryoneAllowedToParticipateAfterDelay &&
      _wasStarted &&
      block.timestamp >= (_saleStart + EVERYONE_ALLOCATION_DELAY)
    ) {
      return true;
    }

    return bool(_allowedParticipants[participant]);
  }

  /**
   * @dev Checks if sale is active.
   */
  function isActive() public view returns (bool) {
    return (_wasStarted && !_wasClosed);
  }

  /**
   * @dev Checks if everyone is allowed to participate after delay.
   */
  function isEveryoneAllowedToParticipateAfterDelay() public view returns (bool) {
    return _isEveryoneAllowedToParticipateAfterDelay;
  }

  /**
   * @dev Returns minimum allocation amount.
   */
  function minimumAllocation() public view returns (uint256) {
    return _minimumAllocation;
  }

  /**
   * @dev Returns maximum allocation amount.
   */
  function maximumAllocation() public view returns (uint256) {
    return _maximumAllocation;
  }

  /**
   * @dev Returns the participants list.
   */
  function participants() public view returns (address[] memory) {
    return _participants;
  }

  /**
   * @dev Returns sale start timestamp.
   */
  function saleStart() public view returns (uint256) {
    return _saleStart;
  }

  /**
   * @dev Returns total allocations limit.
   */
  function totalAllocationsLimit() public view returns (uint256) {
    return _totalAllocationsLimit;
  }

  /**
   * @dev Returns allocated amount.
   */
  function totalAllocated() public view returns (uint256) {
    return _totalAllocated;
  }

  /**
   * @dev Checks if sale was already started.
   */
  function wasStarted() public view returns (bool) {
    return _wasStarted;
  }

  /**
   * @dev Checks if sale was already closed.
   */
  function wasClosed() public view returns (bool) {
    return _wasClosed;
  }

  /**
   * @dev Fallback receive method.
   */
  receive() external payable {
    allocate();
  }
}
