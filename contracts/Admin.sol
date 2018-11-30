pragma solidity ^0.4.18;
import "./AuthorityGranter.sol";

contract Admin is AuthorityGranter {  
  
    uint private abandonPeriod = 100000;
    uint private minWagerAmount = 10;
    uint private callbackInterval = 1;     
    uint private minOracleStake = 1;
    uint private minEventBond = 10000;
    uint private maxOracleInterval= 604800; //Time in seconds allowed since the last event an oracle service was performed (to win lottery)
    uint private oraclePeriod = 1800; // TIme in seconds the oracles have to report a score before an event can be finalized
    uint private eventMakerFinalizeCushion = 3600; //TIme an event creator has after the oracle period ends to finalize the event before their reward can be stolen
    uint private eventMakerRewardDivider = 10000;
    uint private callbackGasLimit = 900000;
    int private oracleRepPenalty = 4;
    int private oracleRepReward = 1;
    int private playerAgreeRepReward = 1;
    int private playerDisagreeRepPenalty = 4;
    
    mapping (bytes32 => uint) private minOracleNum;

    function setAbandonPeriod(uint newPeriod) external onlyAuth { abandonPeriod = newPeriod; }

    function setEventMakerFinalizeCushion(uint newCushion) external onlyAuth { eventMakerFinalizeCushion = newCushion; }    

    function setMinEventBond(uint newBond) external onlyAuth { minEventBond = newBond; }         

    function setMinOracleStake (uint newMin) external onlyAuth { minOracleStake = newMin; }

    function setMinOracleNum (bytes32 eventId, uint min) external onlyAuth { minOracleNum[eventId] = min; }

    function setMaxOracleInterval (uint max) external onlyAuth { maxOracleInterval = max; }

    function setOraclePeriod (uint newPeriod) external onlyAuth { oraclePeriod = newPeriod; }  

    function setOracleRepPenalty (int penalty) external onlyAuth { oracleRepPenalty = penalty; } 

    function setOracleRepReward (int reward) external onlyAuth { oracleRepReward = reward; }

    function setPlayerAgreeRepReward (int reward) external onlyAuth { playerAgreeRepReward = reward; }

    function setPlayerDisagreeRepPenalty (int penalty) external onlyAuth { playerDisagreeRepPenalty = penalty; }  

    function setCallbackGasLimit (uint newLimit) external onlyAuth { callbackGasLimit = newLimit; }    
    
  /** @dev Sets a new number for the interval in between callback functions.
    * @param newInterval The new interval between oraclize callbacks.        
    */
    function setCallbackInterval(uint newInterval) external onlyAuth { callbackInterval = newInterval; }

  /** @dev Updates the minimum amount of ETH required to make a wager.
    * @param minWager The new required minimum amount of ETH to make a wager.
    */
    function setMinWagerAmount(uint256 minWager) external onlyAuth { minWagerAmount = minWager; }

    function getAbandonPeriod() external view returns (uint) { return abandonPeriod; } 
    
    function getCallbackGasLimit() external view returns (uint) { return callbackGasLimit; }  
    
    function getCallbackInterval() external view returns (uint) { return callbackInterval; }

    function getEventMakerFinalizeCushion() external view returns (uint) { return eventMakerFinalizeCushion; }

    function getEventMakerRewardDivider() external view returns (uint) { return eventMakerRewardDivider; }

    function getMaxOracleInterval() external view returns (uint) { return maxOracleInterval; } 

    function getMinEventBond() external view returns (uint) { return minEventBond; } 
    
    function getMinOracleNum (bytes32 eventId) external view returns (uint) { return minOracleNum[eventId]; }

    function getMinOracleStake () external view returns (uint) { return minOracleStake; }   
    
    function getMinWagerAmount() external view returns (uint) { return minWagerAmount; }

    function getOraclePeriod() external view returns (uint) { return oraclePeriod; }
    
    function getOracleRepPenalty () external view returns (int) { return oracleRepPenalty; }

    function getOracleRepReward () external view returns (int) { return oracleRepReward; }

    function getPlayerAgreeRepReward () external view returns (int) { return playerAgreeRepReward; }

    function getPlayerDisagreeRepPenalty () external view returns (int) { return playerDisagreeRepPenalty; }
}