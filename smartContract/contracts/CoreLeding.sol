// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IlendingPool.sol";
import "./IBlacklist.sol";
import "./IAuctionManager.sol";

contract CoreLending is Ownable {
    ILendingPool public lendingPool;
    IBlacklist public blacklist;
    IAuctionManager public auctionManager;
    
    event Borrowed(address indexed user, uint256 loanId, uint256 amount, uint256 dueTime);
    event Repaid(address indexed user, uint256 loanId, uint256 amount);
    
    constructor(address _lendingPool, address _blacklist, address _auctionManager) {
        lendingPool = ILendingPool(_lendingPool);
        blacklist = IBlacklist(_blacklist);
        auctionManager = IAuctionManager(_auctionManager);
    }
    
    function borrow(uint256 amount, uint256 collateralAmount, uint256 duration) external {
        require(!blacklist.isBlacklisted(msg.sender), "Blacklisted user");
        lendingPool.borrow(msg.sender, amount, collateralAmount, duration);
        emit Borrowed(msg.sender, loans[msg.sender].length - 1, amount, block.timestamp + duration);
    }
    
    function repay(uint256 loanId) external {
        lendingPool.repay(msg.sender, loanId);
        emit Repaid(msg.sender, loanId, loans[msg.sender][loanId].amount);
    }
    
    function liquidate(address user, uint256 loanId) external {
        (bool needsAuction, uint256 shortage) = lendingPool.liquidate(user, loanId);
        if (needsAuction) {
            blacklist.addToBlacklist(user);
            auctionManager.startAuction(user, loanId, shortage);
        }
    }
    
    function setLendingPool(address _lendingPool) external onlyOwner {
        lendingPool = ILendingPool(_lendingPool);
    }
    
    function setBlacklist(address _blacklist) external onlyOwner {
        blacklist = IBlacklist(_blacklist);
    }
    
    function setAuctionManager(address _auctionManager) external onlyOwner {
        auctionManager = IAuctionManager(_auctionManager);
    }
}