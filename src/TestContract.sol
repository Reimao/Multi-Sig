// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

contract TestContract {

  uint256 public a;

  receive() external payable {}
  fallback() external payable {}

  function balance() public view returns (uint256) {
    return address(this).balance;
  }

  function setA(uint256 _a) public returns (uint256) {
    a = _a;
    return a;
  }

}

