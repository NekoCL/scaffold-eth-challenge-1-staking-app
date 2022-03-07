pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  //uint256 public deadline = block.timestamp + 30 seconds;
  uint256 public deadline = block.timestamp + 72 hours;

  event Stake(address indexed sender, uint256 amount);
  event emitBal(uint256 balAmount);

  modifier deadlineNotReached() {
    require(timeLeft() > 0, 'Deadline reached');
    _;
  }

  modifier deadlineReached() {
    require(timeLeft() == 0, 'Deadline not reached');
    _;
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, 'Staking already complete');
    _;
  }

  function stake() external payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted deadlineReached {
    if (address(this).balance > threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw(address payable withdrawingUser) public deadlineReached notCompleted {
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, 'No balance to withdraw');
    balances[msg.sender] = 0;
    (bool sent, ) = withdrawingUser.call{value: userBalance}('');
    require(sent, 'Failed to withdraw');
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256 timeleft) {
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    require(msg.value > 0);
    balances[msg.sender] += msg.value;
  }
}
