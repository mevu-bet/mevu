pragma solidity 0.4.18;
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Admin is Ownable {   
    
    uint minWagerAmount = 10;
    uint callbackInterval = 250;
    uint minOracleStake = 1;
    uint callbackGasLimit = 600000;
    uint minOracleNum = 7;  
  

   

    function setMinOracleStake (uint newMin) external onlyOwner {
        minOracleStake = newMin;
    }    

    function setCallbackGasLimit (uint newLimit) external onlyOwner {
        callbackGasLimit = newLimit;
    }

    
    
    /** @dev Sets a new number for the interval in between callback functions.
      * @param newInterval The new interval between oraclize callbacks.        
      */
    function setCallbackInterval(uint newInterval) external onlyOwner {  
       callbackInterval = newInterval;
    }

    /** @dev Updates the minimum amount of ETH required to make a wager.
      * @param minWager The new required minimum amount of ETH to make a wager.
      */
    function setMinWagerAmount(uint256 minWager) external onlyOwner {
        minWagerAmount = minWager;
    }  

    
    function getCallbackInterval() external view returns (uint) {
       return callbackInterval;
    }
    
    function getMinWagerAmount() external view returns (uint) {
       return minWagerAmount;
    }

    function getMinOracleStake () external view returns (uint) {
        return minOracleStake;
    }

    function getCallbackGasLimit() external view returns (uint) {
        return callbackGasLimit;
    }

    function getMinOracleNum () external view returns (uint) {
        return minOracleNum;
    }
    
 

}