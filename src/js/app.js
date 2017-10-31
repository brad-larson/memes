App = {
  web3Provider: null,
  contracts: {},

  init: function() {
    return App.initWeb3();
  },

  initWeb3: function() {
    // Initialize web3 and set the provider to the testRPC.
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // set the provider you want from Web3.providers
      App.web3Provider = new web3.providers.HttpProvider('http://localhost:8545');
      web3 = new Web3(App.web3Provider);
    }

    return App.initContract();
  },

  initContract: function() {
    $.getJSON('MemeToken.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract.
      var MemeTokenArtifact = data;
      App.contracts.MemeToken = TruffleContract(MemeTokenArtifact);

      // Set the provider for our contract.
      App.contracts.MemeToken.setProvider(App.web3Provider);
      $('#myWalletAddress').text(web3.eth.accounts[0]);
      App.getBalances();
      App.getTrades();
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '#transferButton', App.handleTransfer);
    $(document).on('click', '#buyFromContract', App.handleBuy);
    $(document).on('click', '#sellToContract', App.handleSell);
    $(document).on('click', '#createOrder', App.handleCreateOrder);
    $(document).on('click', '#exchangeMemes', App.handleExchange);
    $(document).on('click', '.cancel-order', App.cancelTrade);
  },

  handleTransfer: function() {
    event.preventDefault();

    var amount = parseInt($('#MTTransferAmount').val());
    var toAddress = $('#MTTransferAddress').val();

    console.log('Transfer ' + amount + ' MT to ' + toAddress);

    var tutorialTokenInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) { console.log(error); }
      var account = accounts[0];
      App.contracts.MemeToken.deployed().then(function(instance) {
        tutorialTokenInstance = instance;
        return tutorialTokenInstance.transfer(toAddress, amount, {from: account});
      }).then(function(result) {
        alert('Transfer Successful!');
        return App.getBalances();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },

  handleBuy: function() {
    event.preventDefault();
    var contract;
    App.contracts.MemeToken.deployed().then(function(instance) {
      contract = instance;
      return instance.buyPrice.call();
    }).then(function(result) {
      var price = result.toNumber();
      console.log(price, result.toString());
      if (confirm("Are you sure you want to buy 1 MT for "+ web3.fromWei(price, 'ether'))) {
        return contract.buyFromContract({ value: price * 2, gas: 2000000 });
      }
      else { throw 'User rejected transaction'; }
    }).then(function(tx) {
      console.log(tx);
      App.getBalances();
    }).catch(function(err) {
      console.log(err);
    });
  },

  handleSell: function() {
    event.preventDefault();
    var contract;
    App.contracts.MemeToken.deployed().then(function(instance) {
      contract = instance;
      return instance.sellPrice.call();
    }).then(function(result) {
      var price = result.toNumber();
      if (confirm("Are you sure you want to sell 1 MT for "+ web3.fromWei(price, 'ether'))) {
        return contract.sellToContract();
      }
      else { throw 'User rejected transaction'; }
    }).then(function(tx) {
      console.log(tx);
      App.getBalances();
    }).catch(function(err) {
      console.log(err);
    });
  },

  // This function will need to keep track of buy/sell, but not sure if the contract does
  handleCreateOrder: function() {
    var orderShares = parseInt($('#orderShares').val());
    var orderAmount = web3.toWei(parseInt($('#orderAmount').val()), 'ether');
    var signer = web3.eth.accounts[0];
    var contract;
    var order = {
      shares: orderShares,
      amount: orderAmount,
      signer: signer,
      signature: null
    };

    var hash = App.contracts.MemeToken.deployed().then(function(instance) {
      contract = instance;
      return instance.hashUnboundedOrder.call(signer, orderShares, orderAmount);
    }).then(function(hash) {
      console.log(hash);
      return web3.eth.sign(signer, hash, function(err, result) {
        order.signature = result;
        $('#myOrders').append(App.makeOrder(order));
      });
    }).then(function(sign) {
      console.log(sign);
    }).catch(function(err) {
      console.log(err);
    });
  },

  handleExchange: function() {
    event.preventDefault();
    var buyerAddress = $('#buyerAddress').val();
    var sellerAddress = $('#sellerAddress').val();
    var numShares = parseInt($('#numShares').val());
    var ethAmount = web3.toWei(parseInt($('#ethAmount').val()), 'ether');
    var buyerSig = $('#buyerSig').val();
    var sellerSig = $('#sellerSig').val();
    var contract;
    App.contracts.MemeToken.deployed().then(function(instance) {
      contract = instance;
      return instance.exchange(
        buyerAddress,
        sellerAddress,
        numShares,
        ethAmount,
        buyerSig,
        sellerSig
      );
    }).then(function(tx) {
      console.log(tx);
    }).catch(function(err) {
      console.log(err);
    });
  },

  getBalances: function() {
    console.log('Getting balances...');

    var tutorialTokenInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.MemeToken.deployed().then(function(instance) {
        tutorialTokenInstance = instance;

        tutorialTokenInstance
          .buyPrice
          .call()
          .then(function(result) { $('#BuyPrice').text(web3.fromWei(result.toNumber()), 'ether'); });

        tutorialTokenInstance
          .sellPrice
          .call()
          .then(function(result) { $('#SellPrice').text(web3.fromWei(result.toNumber()), 'ether'); });

        return tutorialTokenInstance.balanceOf(account);
      }).then(function(result) {
        balance = result.c[0];
        console.log(balance);

        $('#MTBalance').text(balance);
      }).then(function(result) {
      }).catch(function(err) {
        console.log(err.message);
      });
    });
  },
  makeTrade: function(trade) {
    var li = '<li>' + trade[2].toNumber() + ' shares for ' + web3.fromWei(trade[3].toNumber(), 'ether') + ' ETH';
    li += ' from ' + trade[0] + ' to ' + trade[1] + '</li>';
    return li;
  },
  makeOrder: function(order) {
    var li = '<li style="word-wrap:break-word;">' + order.shares + ' shares for ' + web3.fromWei(order.amount, 'ether') + ' ETH';
    li += '<br />' + order.signature + ' ' + App.makeCancelLink(order) + '</li>';
    return li;
  },
  makeCancelLink: function(order) {
    var a = '<a href="#" class="cancel-order" data-shares="' + order.shares + '" data-amount="' + order.amount + '" data-sig="' + order.signature +'">Cancel Order</a>';
    return a;
  },
  cancelTrade: function() {
    event.preventDefault();
    var params = event.srcElement.dataset;
    App.contracts.MemeToken.deployed().then(function(instance) {
      return instance.updateOrderCancellation(
        params.shares,
        params.amount,
        params.sig,
        true
      );
    }).then(function(tx) {
      console.log(tx);
    }).catch(function(err) {
      console.log(err);
    });
  },
  getTrades: function() {
    var contract;
    App.contracts.MemeToken.deployed().then(function(instance) {
      contract = instance;
      for(var i = 0; i < 25; i++) {
        contract.lastTrades.call(i).then(function(trade) {
          if (trade[2].toNumber() !== 0) {
            $('#tradesList').append(App.makeTrade(trade));
          }
        });
      }
    }).catch(function(err) {
      console.log(err);
    });
  },
};


$(function() {
  $(window).load(function() {
    App.init();
  });
});
