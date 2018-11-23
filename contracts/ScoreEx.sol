pragma solidity ^0.4.24;

contract ERC20 {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  function getSymbol() public constant returns(string);
}

contract ScoreEx {
	
	struct Good {
	     address outType;
	     address inType;
	     address sellerAddress;
	     uint256 amount;
	     uint256 reminingAmount;
	     uint256 rate;// outType * rate = inType
	     bool  isLock;
	     bool  isSelling;
	     uint  goodId;
	     string outName;
	     string inName;
	}

	struct Offer {
	    address sellerAddress;
	    address buyerAddress;
	    uint256 outAmount;
	    uint256 inAmount;
	    address outType;
	    address inType;
	    uint goodId;
	    uint state;
	    uint offerId;
	}

    event AddGood(address party,uint goodId,address outType,address inType,uint256 amount);


	Good[] public goods;
	Offer[] public offers;


	constructor() public {

	}

	function goodsLen() public constant returns(uint) {
	    return goods.length;
	}

	function getGood(uint goodIndex) public constant returns (address, address, address, uint256, uint256, uint256, bool, bool, uint, string, string) {
	    Good storage good = goods[goodIndex];
		return (good.outType,good.inType,good.sellerAddress,good.amount,good.reminingAmount,good.rate,good.isLock,good.isSelling,good.goodId,good.outName,good.inName);
	}

	function lockGood(uint goodId) public returns (bool success) {
	    return goods[goodId].isLock = true;
	}

	function addGood(address outType,address inType,address sellerAddress,uint256 amount) public returns (uint length) {
	    require(outType != address(0),"outType address error");
	    require(inType != address(0),"inType address error");
	    require(sellerAddress != address(0),"sellerAddress address error");
	    require(amount != 0,"amount is error");
	    uint tempGoodId = goods.length;
	    
	    ERC20 outToken = ERC20(outType);
	    ERC20 inToken = ERC20(inType);
	    goods.push(Good({outType:outType,
	          inType:inType,
	          sellerAddress:sellerAddress,
	          amount:amount,
	          reminingAmount:amount,
              rate:1,
              isSelling:true,
	          isLock:false,
	          goodId:tempGoodId,
	          outName:outToken.getSymbol(),
	          inName:inToken.getSymbol()
	          }));
	    //outToken.approve(address(this),amount);
	    AddGood(msg.sender,tempGoodId,outType,inType,amount);
	    return goods.length;
	}

	function removeGood(uint goodId) public returns(bool success) {
        delete goods[goodId];
        return true;
	}

	function addOffer(uint goodId,address buyerAddress,uint256 outAmount,uint256 inAmount) public returns(uint length) {
        Good storage good = goods[goodId];
        if (good.outType == 0){
           return 2;
        }
        //else{
        //   return 9;
        //}
        //return test;
        if (outAmount > good.reminingAmount){
           return 3;
        }
        //else{
        //   return 10;
        //}
        //require(outAmount <= good.reminingAmount,"reminingAmount low then amount");
        good.reminingAmount = good.amount - outAmount;
        //good.isLock = true;
        uint tempOfferId = offers.length;
	    
        offers.push(Offer({
                                     sellerAddress:good.sellerAddress,
                                     buyerAddress:buyerAddress,
                                     outAmount:outAmount,
                                     inAmount:inAmount,
                                     outType:good.outType,
                                     inType:good.inType,
                                     goodId:goodId,
                                     state:1,
                                     offerId:tempOfferId
                                     }));

        ERC20 outToken = ERC20(good.outType);
        //if (address(outToken) == 0x0) {
        //   return 4;
        //}
        //else{
        //   return 11;
        //}

	    ERC20 inToken = ERC20(good.inType);
	    //if(address(inToken) == 0x0) {
        //   return 5;
        //}
        //else{
        //   return 12;
        //}

	    bool flag = outToken.transfer(buyerAddress,outAmount);
	    //if (!flag) {
	    //   return 6;
	    //}
	    //else{
        //   return 13;
        //}
	    //bool approve = inToken.approve(address(this),inAmount);
	    //if (!approve) {
	    //   return 7;
	    //}
	    //else{
        //   return 14;
        //}
	    bool transferFrom = inToken.transfer(good.sellerAddress,inAmount);
	    //if(!transferFrom) {
	    //  return 8;
	    //}
	    //else{
        //   return 15;
        //}

	    if (good.reminingAmount <= 0){

	        uint len = goods.length;
            if (goodId >= len) return 0;
            for (uint i = goodId; i< len-1; i++) {
                goods[i] = goods[i+1];
            }
            delete goods[len-1];
            goods.length--;
	       //delete goods[goodId];
	    }
        return offers.length;
	}

	function allOffers() public constant returns(uint){
	    return offers.length;
	}

    function getOffer(uint offerId) public constant returns (address,address,uint256,uint256,uint,uint,uint) {
      return (offers[offerId].sellerAddress,offers[offerId].buyerAddress,offers[offerId].outAmount,offers[offerId].inAmount,offers[offerId].goodId,offers[offerId].state,offers[offerId].offerId);
    }
	//结束订单并付货

}