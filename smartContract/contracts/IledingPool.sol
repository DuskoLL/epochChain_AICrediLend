// ILendingPool.sol
interface ILendingPool {
    function borrow(address user, uint256 amount, uint256 collateralAmount, uint256 duration) external;
    function repay(address user, uint256 loanId) external;
    function liquidate(address user, uint256 loanId) external returns (bool needsAuction, uint256 shortage);
    function getLoan(address user, uint256 loanId) external view returns (LendingPool.Loan memory);
}

// IBlacklist.sol
interface IBlacklist {
    function isBlacklisted(address account) external view returns (bool);
    function addToBlacklist(address account) external;
    function removeFromBlacklist(address account) external;
}

// IAuctionManager.sol
interface IAuctionManager {
    function startAuction(address user, uint256 loanId, uint256 shortage) external;
    function bid(uint256 auctionId, uint256 bidAmount) external;
    function settleAuction(uint256 auctionId) external;
}