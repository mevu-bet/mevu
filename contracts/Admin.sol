pragma solidity 0.4.18;
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Admin is Ownable {   
    mapping (address => bool) private isAuthorized;    
    uint minWagerAmount = 10;
    uint callbackInterval = 15;
    uint minOracleStake = 1;
    uint callbackGasLimit = 600000;
    int oracleRepPenalty = 25;
    mapping (bytes32 => uint) minOracleNum;   
    
    modifier onlyAuth () {
        require(isAuthorized[msg.sender]);               
        _;
    }

    function grantAuthority (address nowAuthorized) onlyOwner {
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) onlyOwner {
        isAuthorized[unauthorized] = false;
    }

    function setMinOracleStake (uint newMin) external onlyOwner {
        minOracleStake = newMin;
    }

    function setMinOracleNum (bytes32 eventId, uint min) external onlyAuth {
        minOracleNum[eventId] = min;

    }  

    function setOracleRepPenalty (int penalty) external onlyOwner {
        oracleRepPenalty = penalty;
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
    
    function getOracleRepPenalty () external view returns (int) {
        return oracleRepPenalty;
    }

    function getCallbackGasLimit() external view returns (uint) {
        return callbackGasLimit;
    }

    function getMinOracleNum (bytes32 eventId) external view returns (uint) {
        return minOracleNum[eventId];
    }
 

}