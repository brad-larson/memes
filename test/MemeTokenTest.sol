pragma solidity ^0.4.15;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MemeToken.sol";

contract MemeTokenTest {
  uint public initialBalance = 1 ether;

  function testInitialSupply() {
    MemeToken hehe = MemeToken(DeployedAddresses.MemeToken());

    uint expected = 5;

    Assert.equal(hehe.balanceOf(tx.origin), expected, "Owner should have 5 laughs initially");
  }

  function testBuyFromContract() {
    MemeToken hehe = MemeToken(DeployedAddresses.MemeToken());

    hehe.buyFromContract();

    uint expected = 6;

    Assert.equal(hehe.balanceOf(tx.origin), expected, "Owner should have 6 laughs now");
  }
}
