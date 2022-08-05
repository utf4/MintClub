pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT Licensed
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract ARISwapToken is ERC721URIStorage, Ownable {
    constructor() ERC721("ARISwap", "ARI") {
        
    }
    // using Counters for Counters.Counter;   
    using SafeMath for uint;
    uint256 public _tokenIds;
    uint256 default_Time=30 minutes;
    uint256 default_Fee=25;
  struct BidingsData{
    uint256 paid;
    bool bidded;
  }
  struct Bidding{
    //   BidingsData[] bids;
      uint256 biddingId;
      bool OpenForBidding;
      uint256 start_time;
      uint256 end_time;
      uint256 bidPrice;
      address winner;
  }
  struct FixedPrice{
      uint256 price;
      address owner;
      uint256 paid;
      address newowner;
      bool forsale;
  }
    uint256 public newCreateNFTPrice=1e15;
    mapping(uint256 => FixedPrice) public Fixedprices; // tokenId => tokenId fixed Price
    mapping(uint256 => Bidding) public biddingInfo; // tokenId => Is tokenId already bidded
    mapping(address=>uint256)public getbiidingByAddress;
    mapping(address=>mapping(uint256=>BidingsData))public bidForBidder;
    // mapping(uint256 => address) public bidders; // tokenId => bidder address
    
    modifier onlyNftOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender,"acceptOffer:only owner");
        _;
    }
    
    event NewOffer(uint256 indexed tokenId,uint256 indexed price);
    event OfferAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    event OfferSale(address, uint256 tokenId);
    event OfferBuyFixedPrice(address owner, address buyer, uint256 TokenId);
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/";
    }
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function createNewNFT(address to, string memory tokenUri)  payable external returns (uint256 newID) {
        require(msg.value>=newCreateNFTPrice, "Insufficient amount");
         _tokenIds++;
        newID=_tokenIds;
        _safeMint(to, newID);
        _setTokenURI(newID, tokenUri);
        return newID;
    }
    
    receive () external payable {} 
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance); 
    }
    function openNFTForBidding(uint256 tokenId) public onlyNftOwner(tokenId) returns(bool){
      biddingInfo[tokenId].OpenForBidding=true;
      biddingInfo[tokenId].start_time=block.timestamp;
      biddingInfo[tokenId].end_time=block.timestamp.add(default_Time);
    
      return true;
    }
    // 1 day = 86400 convert it into miliseconds
function openNFTForBiddingForSpecific(uint256 tokenId, uint256 timedurantion) public onlyNftOwner(tokenId) returns(bool){
      biddingInfo[tokenId].OpenForBidding=true;
      biddingInfo[tokenId].start_time=block.timestamp;
       biddingInfo[tokenId].end_time=block.timestamp.add(timedurantion);
      return true;
    }
    
    function placeBid(uint256 tokenId) external payable {
        require(biddingInfo[tokenId].OpenForBidding,"Bidding is not open yet");
        require(block.timestamp<=biddingInfo[tokenId].end_time,"Bidding time is ended");
        require(msg.value > 0,"Price must be non-zero");
        require(_exists(tokenId),"Non-existent tokenId");
        require(biddingInfo[tokenId].bidPrice<msg.value,"You are paying less price from previous bid");
        // biddingInfo[tokenId]= biddingInfo[tokenId].biddingId;
        biddingInfo[tokenId].biddingId=biddingInfo[tokenId].biddingId.add(1);
        biddingInfo[tokenId].bidPrice=msg.value;
        biddingInfo[tokenId].winner = msg.sender;
        getbiidingByAddress[msg.sender]=biddingInfo[tokenId].biddingId;
        bidForBidder[msg.sender][biddingInfo[tokenId].biddingId].paid=msg.value;
        bidForBidder[msg.sender][biddingInfo[tokenId].biddingId].bidded=true;
        emit NewOffer(tokenId,msg.value);
    }    
    function acceptOffer(uint256 tokenId) external onlyNftOwner(tokenId){
        require(ownerOf(tokenId) == msg.sender,"acceptOffer:only owner");
        require(_exists(tokenId),"Non-existent tokenId");
        require(biddingInfo[tokenId].winner != address(0),"There is no winner address");
        // super.approve(biddingInfo[tokenId].winner,tokenId);
        super._safeTransfer(msg.sender,biddingInfo[tokenId].winner,tokenId,"0x");
        address payable buyer = payable(msg.sender);
        uint256 amountFee=biddingInfo[tokenId].bidPrice.mul(default_Fee.div(1000));
        buyer.transfer(biddingInfo[tokenId].bidPrice.sub(amountFee));
        payable(owner()).transfer(amountFee);
        delete biddingInfo[tokenId];
        emit OfferAccepted(tokenId,biddingInfo[tokenId].bidPrice,
        msg.sender,biddingInfo[tokenId].winner);
        // emit OfferAccepted(tokenId,biddingInfo[biddingInfo[tokenId].biddingId].bidPrice, msg.sender,
        // biddingInfo[biddingInfo[tokenId].biddingId].winner);
    }
    function ClaimFundsAfterBidding(uint256 tokenId)public returns (bool){
    //  uint256 a= bidForBidder[msg.sender];
     require(bidForBidder[msg.sender][biddingInfo[tokenId].biddingId].bidded,"didn't bid ");
     payable(msg.sender).transfer(bidForBidder[msg.sender][biddingInfo[tokenId].biddingId].paid);
     delete bidForBidder[msg.sender][biddingInfo[tokenId].biddingId];
     return true;
    }

    function PutOnSale(uint256 tokenId)public onlyNftOwner(tokenId) returns(bool){
      
       Fixedprices[tokenId].owner=msg.sender;
        Fixedprices[tokenId].forsale=true;
        emit OfferSale(msg.sender,tokenId);
        return true;
    }
    function BuyFixedPriceNFTs(uint256 tokenId)payable public returns(bool){
        require(msg.value>=Fixedprices[tokenId].price, "send lower amount in fixed price");
        require(Fixedprices[tokenId].forsale,"This NFT is not for sale");
         Fixedprices[tokenId].paid=msg.value;
         Fixedprices[tokenId].newowner=msg.sender;
         return true;
 
    }

    function acceptOfferForFixedPrice(uint256 tokenId)public onlyNftOwner(tokenId) returns(bool){
        require(Fixedprices[tokenId].newowner!=(address(0)),"there is no buyer for this sale");

        super._safeTransfer(msg.sender,Fixedprices[tokenId].newowner,tokenId,"0x");
                
        uint256 amountFee=biddingInfo[tokenId].bidPrice.mul(default_Fee.div(1000));
        payable(Fixedprices[tokenId].owner).transfer(Fixedprices[tokenId].paid.sub(amountFee));
        payable(owner()).transfer(amountFee);
        delete Fixedprices[tokenId];
        emit OfferBuyFixedPrice(Fixedprices[tokenId].owner,msg.sender,tokenId);
        return true;

    }
  function getBiddingData(uint256 tokenId)public view returns(
   uint256,bool,uint256,uint256,uint256,address
  ){
return(biddingInfo[tokenId].biddingId,
biddingInfo[tokenId].OpenForBidding,
biddingInfo[tokenId].start_time,
biddingInfo[tokenId].end_time,
biddingInfo[tokenId].bidPrice,
biddingInfo[tokenId].winner);
  }


    function ChangeNewCreateNFTPrice(uint256 value)public onlyOwner returns(bool){
      newCreateNFTPrice=value;
      return true;
    }

    function setDefaultFee (uint256 value)public onlyOwner returns(bool){
      default_Fee=value;
      return true;
    }

    function setDefaultTime (uint256 value)public onlyOwner returns(bool){
      default_Time=value;
      return true;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
        
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}