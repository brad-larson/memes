pragma solidity ^0.4.4;
import '/Users/bradlarson/src/eth-token/contracts/BurnableToken.sol';
import "/Users/bradlarson/src/eth-token/contracts/strings.sol";
import 'zeppelin-solidity/contracts/token/MintableToken.sol';

contract MemeToken is BurnableToken, MintableToken {
  using strings for *;

  struct Trade {
    address seller;
    address buyer;
    uint shares;
    uint amount;
  }

  string public name = 'MemeToken';
  string public symbol = 'HEH';
  uint public decimals = 0;
  uint public INITIAL_SUPPLY = 5;
  uint public STARTING_PRICE = 1 finney;
  uint public buyPrice = 1 finney;
  uint public sellPrice = buyPrice;
  Trade[25] public lastTrades;
  mapping (address => uint) public deposits; // This will allow for withdraw pattern and pre-funding by buyer

  // Maps the order sig to whether or not it has been cancelled
  // This would only matter for orders that are open ended
  mapping (bytes => bool) cancelledOrders;

  function MemeToken(string _name) {
    name = _name;
    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    // This should reset the price to 0, unless the contract was seeded with some ETH
    trackTrade(Trade(0x0, msg.sender, INITIAL_SUPPLY, INITIAL_SUPPLY * STARTING_PRICE));
  }

  // Modifiers
  modifier hasSufficientBalance(address seller, uint shares) {
    require(balances[seller] >= shares);
    _;
  }

  modifier hasSufficientFunds(uint amount) {
    require(msg.value >= amount);
    _;
  }

  modifier hasSufficientDeposits(address _address, uint amount) {
    require(deposits[_address] >= amount);
    _;
  }

  // modifier validSignature(address _address, uint shares, uint amount, bytes signature) {
  //   require(verifySignature(hashUnboundedOrder(_address, shares, amount), signature, _address));
  //   _;
  // }

  // modifier validSigWithTTL(address _address, uint shares, uint amount, uint validUntil, bytes signature) {
  //   require(verifySignature(shares, amount, validUntil, signature, _address));
  //   _;
  // }

  // Roughly 610k gas
  // Might want to update this to be able to use deposits
  function buyFromContract() payable hasSufficientFunds(buyPrice) {
    uint currentBuyPrice = buyPrice;
    uint change = msg.value - currentBuyPrice;

    totalSupply = totalSupply.add(1);
    balances[msg.sender] = balances[msg.sender].add(1);

    trackTrade(Trade(0x0, msg.sender, 1, currentBuyPrice));
    Mint(msg.sender, 1);

    if (change > 0) {
      // msg.sender.transfer(change); //This might not be safe, so use a deposit (pull) method for now
      deposits[msg.sender] = deposits[msg.sender].add(change);
    }
  }

  // Roughly 620k gas
  // Might want to update this to simply credit the seller
  function sellToContract() payable hasSufficientBalance(msg.sender, 1) {
    require(this.balance >= sellPrice);

    totalSupply = totalSupply.sub(1);
    balances[msg.sender] = balances[msg.sender].sub(1);

    trackTrade(Trade(msg.sender, 0x0, 1, sellPrice));
    Burn(msg.sender, 1);

    deposits[msg.sender] = deposits[msg.sender].add(sellPrice);
    // msg.sender.transfer(sellPrice); // This is l
  }

  // This version of exchange accepts unbounded orders
  // where no explicit TTL is set.
  // Instead, you can manually cancel the order
  function exchange(
    address _buyer,
    address _seller,
    uint _shares,
    uint _amount,
    bytes _buyer_signature,
    bytes _seller_signature
  ) payable {
    // Tried putting these into modifiers, but got stack too deep exceptions
    require(_shares > 0);
    require(_amount > 0);
    require(balances[_seller] >= _shares);
    require(!cancelledOrders[_buyer_signature]);
    require(!cancelledOrders[_seller_signature]);

    bool useDeposits = msg.value < _amount;
    if (msg.sender == _seller) {
      useDeposits = true;
      require(deposits[_buyer] >= _amount);
    }
    else {
      require(msg.sender == _buyer);
      require(msg.value >= _amount || deposits[_buyer] >= _amount);
    }

    require(verifySignature(hashOrder(_buyer, _shares, _amount), _buyer_signature, _buyer));
    require(verifySignature(hashOrder(_seller, _shares, _amount), _seller_signature, _seller));

    _exchange(_buyer, _seller, _shares, _amount, useDeposits);
  }

  function exchange(
    address _buyer,
    address _seller,
    uint _shares,
    uint _amount,
    uint _valid_until,
    bytes _buyer_signature,
    bytes _seller_signature
  )
    payable
  {
    require(_shares > 0);
    require(_amount > 0);
    require(now <= _valid_until);
    require(balances[_seller] >= _shares);
    require(!cancelledOrders[_buyer_signature]);
    require(!cancelledOrders[_seller_signature]);

    bool useDeposits = msg.value < _amount;
    if (msg.sender == _seller) {
      useDeposits = true;
      require(deposits[_buyer] >= _amount);
    }
    else {
      require(msg.sender == _buyer);
      require(msg.value >= _amount || deposits[_buyer] >= _amount);
    }

    require(verifySignature(hashOrder(_buyer, _shares, _amount, _valid_until), _buyer_signature, _buyer));
    require(verifySignature(hashOrder(_seller, _shares, _amount, _valid_until), _seller_signature, _seller));

    _exchange(_buyer, _seller, _shares, _amount, useDeposits);
  }

  // 52k gas
  // Allows the sender to cancel a previously posted order
  function updateOrderCancellation(uint shares, uint amount, bytes sig, bool valid) {
    bytes32 hash = hashOrder(msg.sender, shares, amount);
    require(verifySignature(hash, sig, msg.sender));
    cancelledOrders[sig] = valid;
  }

  function updateOrderCancellation(uint shares, uint amount, uint validUntil, bytes sig, bool valid) {
    bytes32 hash = hashOrder(msg.sender, shares, amount, validUntil);
    require(verifySignature(hash, sig, msg.sender));
    cancelledOrders[sig] = valid;
  }

  // This updates the balance held
  function deposit() payable {
    deposits[msg.sender] = deposits[msg.sender].add(msg.value);
  }

  function withdraw(uint amount) payable hasSufficientDeposits(msg.sender, amount) {
    // May need to implement some protections here
    deposits[msg.sender] = deposits[msg.sender].sub(amount);
    require(msg.sender.send(amount));
  }

  function getCancelStatus(bytes sig) constant returns (bool) {
    return cancelledOrders[sig];
  }

  function hashOrder(address person, uint shares, uint amount) constant returns(bytes32) {
    return sha3(person, shares, amount);
  }

  function hashBoundedOrder(address person, uint shares, uint amount) constant returns(bytes32) {
    return sha3(person, shares, amount);
  }

  function hashOrder(address person, uint shares, uint amount, uint validUntil) constant returns(bytes32) {
    return sha3(person, shares, amount, validUntil);
  }

  function _exchange(address buyer, address seller, uint shares, uint amount, bool useDeposits) internal {
    balances[seller] = balances[seller].sub(shares);
    balances[buyer] = balances[buyer].add(shares);

    if (useDeposits) {
      deposits[buyer] = deposits[buyer].sub(amount);
    }
    deposits[seller] = deposits[seller].add(amount);
    uint change = useDeposits ? msg.value : (msg.value - amount);
    deposits[msg.sender] = deposits[msg.sender].add(change);

    trackTrade(Trade(buyer, seller, shares, amount));
    Transfer(buyer, seller, shares);
  }

  function trackTrade(Trade _trade) internal {
    uint price = pricePerShare(_trade);
    uint maxPrice = price;
    uint minPrice = price;
    for (uint i = lastTrades.length - 1; i > 0; i--) {
      lastTrades[i] = lastTrades[(i-1)];
      if (lastTrades[i].shares > 0) {
        price = pricePerShare(lastTrades[i]);
        if (price > maxPrice) { maxPrice = price; }
        else if (price < minPrice) { minPrice = price; }
      }
    }
    lastTrades[0] = _trade;
    if (this.balance < 1 szabo) { minPrice = this.balance; }
    else { minPrice = sellPrice - 1 szabo; }
    buyPrice = maxPrice + 1 szabo;
    Transfer(_trade.seller, _trade.buyer, _trade.shares);
  }

  function pricePerShare(Trade trade) constant internal returns (uint) {
    if (trade.shares <= 0) {
      return 0;
    }
    else if (trade.amount <= 0) {
      return 0;
    }
    return trade.amount / trade.shares;
  }

  function verifySignature(bytes32 hash, bytes sig, address signer) constant returns (bool) {
    return recover(hash, sig) == signer;
  }

  // Stolen from Zeppelin ECRecovery
  function recover(bytes32 hash, bytes sig) constant internal returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }
}
