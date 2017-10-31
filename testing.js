contract = MemeToken.at("0x698b114c418f0add2ca3a56afd9aafa35dc54dbf")
'0x91db353e20db54e4f6ba5c22ada4b11f6d90b81e'
'0x91db353e20db54e4f6ba5c22ada4b11f6d90b81e'
seller = web3.eth.accounts[0]
buyer = web3.eth.accounts[1]
amount = web3.toWei(0.1, 'ether')
shares = 1
sellerSig = '0x9cc140dd30b7a06da2fbfb6655881176a14222626e33995b80a910fc8943dba62642bf68cb6562df61299b70c55b7344e7ddb6ba10359dd862488cc16e474e511c'
buyerSig = '0xf6fdabde8147600fab2295949045aa39475952c7d4ebd099261d1168a17a63140c66c2e430eb3d2666e977bc27fab9885f374a01ccbfe7a8c4c4e5e6c83a07f01c'

  function exchange(
    address _buyer,
    address _seller,
    uint _shares,
    uint _amount,
    bytes _buyer_signature,
    bytes _seller_signature
  ) payable {
contract.exchange(buyer, seller, shares, amount, buyerSig, sellerSig, { value: amount })


buyer = '0x91db353e20db54e4f6ba5c22ada4b11f6d90b81e'
seller = '0x93b3b0b92788a8ee29cbfec01c7acac2810d2b44'
sellerSig = 0x3ae0a8ceec5694b2bac491ace5cde3d959ee57551fd46d497ffde0fd519bd34b1f31e26695012f9bbe065a6bdffd15a4258a470ebf363ef79a2ba7e779adaf6e1c
buyerSig  = 0xfa7205ebb5d4cbf64d0d133a666832be736c6edf45ca38c5e1c0c42aebdda50f3f507d879f6b5ce0c3a1bf1cf8c811357ab40e2d65724ccd650375689844cf821c

0x3c9bb0555badc6a54608f11bc96f5c3ee7d4a273bcce53f04e579eef894c98796a8074143356fb07d61cf54da23864a1e16635d10b8276426722b01fbc7fc3ff1c



0x86494d60a72f1b75e8f136d67dbd776e72ae94c8931c8b6ee0d629034589d4535ba06d22c747af70d30b621e4d018008927e70d762ec8ecdad11a05a8c1776d21b

contract = MemeToken.at("")

0x3ae0a8ceec5694b2bac491ace5cde3d959ee57551fd46d497ffde0fd519bd34b1f31e26695012f9bbe065a6bdffd15a4258a470ebf363ef79a2ba7e779adaf6e1c

contract = MemeToken.at("0x698b114c418f0add2ca3a56afd9aafa35dc54dbf")
contract.test.call(1, 1)

contract.hashUnboundedOrder.call(web3.eth.accounts[0], 1, web3.toWei(1, 'ether'))

lol.hashUnboundedOrder.call(web3.eth.accounts[0], 1, web3.toWei(1, 'ether'))

contract.updateOrder(1, 1, "0x3ae0a8ceec5694b2bac491ace5cde3d959ee57551fd46d497ffde0fd519bd34b1f31e26695012f9bbe065a6bdffd15a4258a470ebf363ef79a2ba7e779adaf6e1c", true)
