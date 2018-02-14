pragma solidity 0.4.18;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Admin is Ownable {   
    mapping (address => bool) private isAuthorized;    
    uint private minWagerAmount = 10;
    uint private callbackInterval = 1;
    uint private minOracleStake = 1;
    uint private maxOracleInterval= 604800; //Time in seconds allowed since the last event an oracle service was performed (to win lottery)
    uint private callbackGasLimit = 900000;
    int private oracleRepPenalty = 4;
    int private oracleRepReward = 1;
    int private playerAgreeRepReward = 1;
    int private playerDisagreeRepPenalty = 4;
    mapping (bytes32 => uint) private minOracleNum;   
    
    modifier onlyAuth () {
        require(isAuthorized[msg.sender]);               
        _;
    }

    function grantAuthority (address nowAuthorized) external onlyOwner {
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) external onlyOwner {
        isAuthorized[unauthorized] = false;
    }

    function setMinOracleStake (uint newMin) external onlyAuth {
        minOracleStake = newMin;
    }

    function setMinOracleNum (bytes32 eventId, uint min) external onlyAuth {
        minOracleNum[eventId] = min;
    }

    function setMaxOracleInterval (uint max) external onlyAuth {
        maxOracleInterval = max;
    }  

    function setOracleRepPenalty (int penalty) external onlyAuth {
        oracleRepPenalty = penalty;
    } 

    function setOracleRepReward (int reward) external onlyAuth {
        oracleRepReward = reward;
    }

    function setPlayerAgreeRepReward (int reward) external onlyAuth {
        playerAgreeRepReward = reward;
    }

    function setPlayerDisagreeRepPenalty (int penalty) external onlyAuth {
        playerDisagreeRepPenalty = penalty;
    }  

    function setCallbackGasLimit (uint newLimit) external onlyAuth {
        callbackGasLimit = newLimit;
    }    
    
    /** @dev Sets a new number for the interval in between callback functions.
      * @param newInterval The new interval between oraclize callbacks.        
      */
    function setCallbackInterval(uint newInterval) external onlyAuth {  
       callbackInterval = newInterval;
    }

    /** @dev Updates the minimum amount of ETH required to make a wager.
      * @param minWager The new required minimum amount of ETH to make a wager.
      */
    function setMinWagerAmount(uint256 minWager) external onlyAuth {
        minWagerAmount = minWager;
    }  
    
    function getCallbackInterval() external view returns (uint) {
       return callbackInterval;
    }

    function getMaxOracleInterval() external view returns (uint) {
       return maxOracleInterval;
    }
    
    function getMinWagerAmount() external view returns (uint) {
       return minWagerAmount;
    }

    function getMinOracleStake () external view returns (uint) {
        return minOracleStake;
    }

    function getOracleRepReward () external view returns (int) {
        return oracleRepReward;
    }

    function getPlayerAgreeRepReward () external view returns (int) {
        return playerAgreeRepReward;
    }

    function getPlayerDisagreeRepPenalty () external view returns (int) {
        return playerDisagreeRepPenalty;
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