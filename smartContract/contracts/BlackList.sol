// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Blacklist is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _blacklist;
    
    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);
    
    function isBlacklisted(address account) external view returns (bool) {
        return _blacklist.contains(account);
    }
    
    function addToBlacklist(address account) external onlyOwner {
        require(_blacklist.add(account), "Already blacklisted");
        emit AddedToBlacklist(account);
    }
    
    function removeFromBlacklist(address account) external onlyOwner {
        require(_blacklist.remove(account), "Not blacklisted");
        emit RemovedFromBlacklist(account);
    }
    
    function getBlacklistedCount() external view returns (uint256) {
        return _blacklist.length();
    }
}