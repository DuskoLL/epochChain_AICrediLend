// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionManager is Ownable {

    IERC20 public tokenA;
    
    ERC20Burnable public tokenB;
    
    enum AuctionType { Collateral, Debt }
    
    struct Auction {
        AuctionType auctionType;
        address user;
        uint256 loanId;
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        uint256 minBid;
        address highestBidder;
        uint256 highestBid;
        bool settled;
    }
    
    Auction[] public auctions;
    uint256 public auctionDuration = 3 days;
    uint256 public debtAuctionDuration = 5 days;
    
    event AuctionStarted(uint256 auctionId, AuctionType auctionType, address user, uint256 loanId, uint256 amount);
    event BidPlaced(uint256 auctionId, address bidder, uint256 amount);
    event AuctionSettled(uint256 auctionId, address winner, uint256 amount);
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = ERC20Burnable(_tokenB);
    }
    
    function startAuction(address user, uint256 loanId, uint256 shortage) external onlyOwner {
        // Start collateral auction
        uint256 collateralAuctionId = auctions.length;
        auctions.push(Auction({
            auctionType: AuctionType.Collateral,
            user: user,
            loanId: loanId,
            startTime: block.timestamp,
            endTime: block.timestamp + auctionDuration,
            amount: 0, // Will be set in settle
            minBid: 0, // Will be set in settle
            highestBidder: address(0),
            highestBid: 0,
            settled: false
        }));
        
        emit AuctionStarted(collateralAuctionId, AuctionType.Collateral, user, loanId, 0);
        
        // If there's a shortage, start debt auction
        if (shortage > 0) {
            tokenB.mint(address(this), shortage);
            uint256 debtAuctionId = auctions.length;
            auctions.push(Auction({
                auctionType: AuctionType.Debt,
                user: address(0),
                loanId: 0,
                startTime: block.timestamp,
                endTime: block.timestamp + debtAuctionDuration,
                amount: shortage,
                minBid: (shortage * 90) / 100,
                highestBidder: address(0),
                highestBid: 0,
                settled: false
            }));
            
            emit AuctionStarted(debtAuctionId, AuctionType.Debt, address(0), 0, shortage);
        }
    }
    
    function bid(uint256 auctionId, uint256 bidAmount) external {
        Auction storage auction = auctions[auctionId];
        require(!auction.settled, "Auction settled");
        require(block.timestamp <= auction.endTime, "Auction ended");
        require(bidAmount > auction.highestBid, "Bid too low");
        require(bidAmount >= auction.minBid, "Bid below minimum");
        
        if (auction.highestBidder != address(0)) {
            require(tokenA.transfer(auction.highestBidder, auction.highestBid), "Refund failed");
        }
        
        require(tokenA.transferFrom(msg.sender, address(this), bidAmount), "Bid transfer failed");
        
        auction.highestBidder = msg.sender;
        auction.highestBid = bidAmount;
        
        emit BidPlaced(auctionId, msg.sender, bidAmount);
    }
    
    function settleAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(!auction.settled, "Auction settled");
        require(block.timestamp > auction.endTime, "Auction not ended");
        
        auction.settled = true;
        
        if (auction.highestBidder != address(0)) {
            if (auction.auctionType == AuctionType.Collateral) {
                // Handle collateral transfer in core contract
            } else {
                require(tokenB.transfer(auction.highestBidder, auction.amount), "TokenB transfer failed");
            }
            emit AuctionSettled(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            if (auction.auctionType == AuctionType.Debt) {
                tokenB.burn(auction.amount);
            }
            emit AuctionSettled(auctionId, address(0), 0);
        }
    }
    
    function setAuctionDuration(uint256 _duration) external onlyOwner {
        auctionDuration = _duration;
    }
    
    function setDebtAuctionDuration(uint256 _duration) external onlyOwner {
        debtAuctionDuration = _duration;
    }
}