// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/interfaces/IERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BlindAuction {

    IERC721 public immutable nft;
    uint public immutable nftId;
    address payable public immutable auctioner;

    uint32 public endTime;
    bool public started;
    bool public ended;
    address public highestBidder;
    uint public highestBid;
    // to store and see the values per bidder and allow withdrawal
    mapping (address => uint) public bids;
    
    constructor( address _nft, uint _nftId, uint _startingBid ) {
        nft = IERC721(_nft);
        nftId = _nftId;
        auctioner = payable(msg.sender);
        highestBidder = _startingBid;
    }

    function start() external {
        require(msg.sender == auctioner, "not seller");
        require(!started, "auction started");
        started = true;
        endTime = uint32(block.timestamp + 600);
        nft.transferFrom(auctioner, address(this), nftId);
        emit Start();
    }

    function Bid() external payable {
        require(started, "not started");
        require(block.timestamp < endTime, "endTime");
        require(msg.value > highestBid, "value < highest");
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        highestBid = msg.value;
        highestBidder = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0; 
        payable(msg.sender.transfer(bal));
        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp >= endTime, "not ended");
        ended = true;
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            auctioner.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), auctioner, nftId);
        }
        emit End(highestBidder, highestBid);
    }

    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address highestBidder, uint amount);
    
}
