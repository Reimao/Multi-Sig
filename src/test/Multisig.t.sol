// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <=0.9.0;

import "ds-test/test.sol";
import "../Multisig.sol";
import "../TestContract.sol";

interface Vm {
  function startPrank(address sender) external;
  function prank(address) external;
}

contract MultisigTest is DSTest {
  Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
  Multisig multisig;
  TestContract testContract;
  address constant signer1 = 0xEb3d7cd47b5CD5Ec46c31A9424143e21D3cA8Ec4;
  address constant signer2 = 0x6434C76494b6F199b2702C0279a755cfecdc6CdB; 
  address constant signer3 = 0x43F16e6dD99D90B394AB762078bbed29e420ECDF;
  address constant signer4 = 0xC6167Bb118A7C739Efe22c57B761847dC6B8aC31; 
  address[] signers; 

  function setUp() public {
    signers.push(signer1);
    signers.push(signer2);
    signers.push(signer3);
    signers.push(signer4);
    
    multisig = new Multisig(signers, 3);
    testContract = new TestContract();
  }
    
  function testConstruct() public {
    multisig = new Multisig(signers, 3);

    assertEq(multisig.signersCount(), 4);
    assertEq(multisig.requiredSignatures(), 3);

  }

  function testFailConstruct_TooManyRequiredSignatures() public {
    multisig = new Multisig(signers, 5);
  }

  function testFailConstruct_ZeroRequiredSignatures() public {
    multisig = new Multisig(signers, 0);
  }

  function testFailConstruct_ZeroAddressSigner() public {
    signers.push(address(0));
    multisig = new Multisig(signers, 2);
  }

  function testFailConstruct_SignerRedundancy() public {
    signers.push(signer1);
    multisig = new Multisig(signers, 3);
  }

  function testInitializeTransaction() public {
    vm.prank(signer2);
    multisig.initializeTransaction(signer1, 10 ether, "");
    (address to, uint256 value, bytes memory data, bool executed) = multisig.transactions(0);

    assertEq(to, signer1);
    assertEq(value, 10 ether);
    assertEq(string(data), "");
    assertTrue(!executed);
  }

  function testSignTransaction() public {
    vm.prank(signer1);
    multisig.initializeTransaction(address(0), 10 ether, "");
    vm.prank(signer2);
    multisig.signTransaction(0);
    
    assertTrue(multisig.hasSigned(0,signer2));
    assertTrue(!multisig.hasSigned(0,signer1));
  }

  function testFailSignTransaction_InexistentTx() public {
    vm.prank(signer1);
    multisig.signTransaction(0);
  }

  function testTestContractReceive() public {
    (bool success, ) = address(testContract).call{value: 5}("");
    require(success, "Transaction failed");

    assertEq(testContract.balance(), 5);
  }

  function testExecuteTransactionNoData() public {
    vm.prank(signer1);
    multisig.initializeTransaction(address(testContract), 50, "");
    
    vm.prank(signer1);
    multisig.signTransaction(0);
    vm.prank(signer2);
    multisig.signTransaction(0);
    vm.prank(signer3);
    multisig.signTransaction(0);

    address(multisig).call{value: 100}("");

    vm.prank(signer1);
    multisig.executeTransaction(0);
  }

  function testExecuteTransactionWithData() public {
    vm.prank(signer1);
    uint256 a;
    bytes memory data = abi.encodeWithSignature("setA(uint256)", a);
    multisig.initializeTransaction(address(testContract), 0, data);
    
    vm.prank(signer1);
    multisig.signTransaction(0);
    vm.prank(signer2);
    multisig.signTransaction(0);
    vm.prank(signer3);
    multisig.signTransaction(0);

    address(multisig).call{value: 100}("");

    vm.prank(signer1);
    bytes memory data2 = multisig.executeTransaction(0);
    assertEq(bytes32(data2), bytes32(abi.encodePacked(a)));
  }
}
