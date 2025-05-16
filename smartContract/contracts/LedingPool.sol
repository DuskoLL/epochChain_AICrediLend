// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPool is Ownable {
    IERC20 public tokenA;
    ERC20Burnable public tokenB;
    
    struct Loan {
        uint256 amount;
        uint256 collateral;
        uint256 dueTime;
        bool liquidated;
    }
    
    mapping(address => Loan[]) public loans;
    uint256 public constant INTEREST_RATE = 10;
    uint256 public constant LIQUIDATION_PENALTY = 5;
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = ERC20Burnable(_tokenB);
    }
    
    function borrow(address user, uint256 amount, uint256 collateralAmount, uint256 duration) external onlyOwner {
        require(collateralAmount >= (amount * 150) / 100, "Insufficient collateral");
        require(tokenB.transferFrom(user, address(this), collateralAmount), "Collateral transfer failed");
        require(tokenA.transfer(user, amount), "Loan transfer failed");
        
        loans[user].push(Loan({
            amount: amount,
            collateral: collateralAmount,
            dueTime: block.timestamp + duration,
            liquidated: false
        }));
    }
    
    function repay(address user, uint256 loanId) external onlyOwner {
        Loan storage loan = loans[user][loanId];
        require(!loan.liquidated, "Loan already liquidated");
        
        uint256 repayment = loan.amount * (100 + INTEREST_RATE) / 100;
        require(tokenA.transferFrom(user, address(this), repayment), "Repayment failed");
        require(tokenB.transfer(user, loan.collateral), "Collateral return failed");
        
        loan.liquidated = true;
    }
    
    function liquidate(address user, uint256 loanId) external onlyOwner returns (bool needsAuction, uint256 shortage) {
        Loan storage loan = loans[user][loanId];
        require(!loan.liquidated, "Loan already liquidated");
        
        uint256 penalty = loan.amount * LIQUIDATION_PENALTY / 100;
        uint256 totalDue = loan.amount + penalty;
        
        if (tokenA.allowance(user, address(this)) >= totalDue && 
            tokenA.balanceOf(user) >= totalDue) {
            require(tokenA.transferFrom(user, address(this), totalDue), "Penalty payment failed");
            require(tokenB.transfer(user, loan.collateral), "Collateral return failed");
            loan.liquidated = true;
            return (false, 0);
        } else {
            return (true, loan.amount);
        }
    }
    
    function getLoan(address user, uint256 loanId) external view returns (Loan memory) {
        return loans[user][loanId];
    }
}