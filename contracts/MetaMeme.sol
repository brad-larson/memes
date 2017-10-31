pragma solidity ^0.4.4;

import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './MemeToken.sol';

contract MetaMeme is StandardToken {
  mapping (bytes32 => address) public memeTokens;
  uint public INITIAL_SUPPLY = 0;

  function MetaMeme() {
    totalSupply = INITIAL_SUPPLY;
  }

  function registerMeme(string meme) {
    bytes32 memeSha = sha3(meme);
    if (memeTokens[memeSha] == 0x0) {
      memeTokens[memeSha] = new MemeToken(meme);
    }
  }

  function getMemeAddress(string memeName) constant returns(address) {
    return memeTokens[sha3(memeName)];
  }
}
