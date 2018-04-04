pragma solidity ^0.4.18;
//import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AuthorityGranter.sol";

contract Oracles is AuthorityGranter {  

    struct OracleStruct { 
        bytes32 eventId;
        uint mvuStake;        
        uint winnerVote;
        bool paid;
    }

    struct EventStruct {
        uint oracleVotes;
        uint totalOracleStake;   
        uint votesForOne;
        uint votesForTwo;
        uint votesForThree;
        uint stakeForOne;
        uint stakeForTwo;
        uint stakeForThree;
        mapping (address => uint) oracleStakes;
        address[] oracles;  
    }

    uint private oracleServiceFee = 3; //Percent
    mapping (address => mapping(bytes32 => bool)) private rewardClaimed;
    mapping (address => mapping(bytes32 => bool)) private refundClaimed;
    mapping (address => mapping(bytes32 => bool)) private alreadyRegistered;    
    mapping (address => mapping (bytes32 => OracleStruct)) private oracleStructs; 
    mapping (bytes32 => EventStruct) private eventStructs;   
    mapping (address => bytes32) private lastEventOraclized;    
    address[] private oracleList; // List of people who have ever registered as an oracle    
    address[] private correctOracles;
    bytes32[] private correctStructs;

    

    function removeOracle (address oracle, bytes32 eventId) external onlyAuth {
        OracleStruct memory thisOracle;
        bytes32 empty;         
        thisOracle = OracleStruct (empty,0,0, false);               
        oracleStructs[oracle][eventId] = thisOracle;    
    }

    function addOracle (address oracle, bytes32 eventId, uint mvuStake, uint winnerVote) external onlyAuth {
        OracleStruct memory thisOracle; 
        thisOracle = OracleStruct (eventId, mvuStake, winnerVote, false);      
        oracleStructs[oracle][eventId] = thisOracle;
        if (winnerVote == 1) {
            eventStructs[eventId].votesForOne ++;
            eventStructs[eventId].stakeForOne += mvuStake; 
        }
        if (winnerVote == 2) {
            eventStructs[eventId].votesForTwo ++;
            eventStructs[eventId].stakeForTwo += mvuStake; 
        }
        if (winnerVote == 3) {
            eventStructs[eventId].votesForThree ++;
            eventStructs[eventId].stakeForThree += mvuStake; 
        }
        eventStructs[eventId].oracleStakes[oracle] = mvuStake;
        eventStructs[eventId].totalOracleStake += mvuStake;
        eventStructs[eventId].oracleVotes += 1;           
    }  


    function addToOracleList (address oracle) external onlyAuth { oracleList.push(oracle); } 

    function setPaid (address oracle, bytes32 eventId) external onlyAuth { oracleStructs[oracle][eventId].paid = true; }  

    function setLastEventOraclized (address oracle, bytes32 eventId) external onlyAuth { lastEventOraclized[oracle] = eventId; }

    function setRefunded (address oracle, bytes32 eventId) external onlyAuth { refundClaimed[oracle][eventId] = true; }

    function setRegistered (address oracle, bytes32 eventId) external onlyAuth { alreadyRegistered[oracle][eventId] = true; }

    function getRegistered (address oracle, bytes32 eventId) external view returns (bool) { return alreadyRegistered[oracle][eventId]; }

    function getWinnerVote(bytes32 eventId, address oracle) external view returns (uint) { return oracleStructs[oracle][eventId].winnerVote; }

    function getPaid (bytes32 eventId, address oracle) external view returns (bool) { return oracleStructs[oracle][eventId].paid; }

    function getRefunded (bytes32 eventId, address oracle) external view returns (bool) { return refundClaimed[oracle][eventId]; }

    function getVotesForOne (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForOne; }

    function getVotesForTwo (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForTwo; }    

    function getVotesForThree (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForThree; } 

    function getStakeForOne (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForOne; }

    function getStakeForTwo (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForTwo; } 

    function getStakeForThree (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForThree; }  

    function getMvuStake (bytes32 eventId, address oracle) external view returns (uint) { return oracleStructs[oracle][eventId].mvuStake; }
   
    function getEventOraclesLength (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].oracles.length; }
    
    function getOracleVotesNum (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].oracleVotes; }   

    function getTotalOracleStake (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].totalOracleStake; }
 
    function getOracleListLength() external  view returns (uint) { return oracleList.length; }

    function getOracleListAt (uint index) external view returns (address) { return oracleList[index]; }

    function getLastEventOraclized (address oracle) external view returns (bytes32) { return lastEventOraclized[oracle]; }  


//         function subTotalOracleStake (bytes32 eventId, uint amount) external onlyAuth {
//         standardEvents[eventId].totalOracleStake -= amount;
//         standardEvents[eventId].oracleVotes -= 1;
//     }

//     function removeOracleFromEvent (bytes32 eventId, uint oracle) external onlyAuth {
//         standardEvents[eventId].oracles[oracle] = standardEvents[eventId].oracles[standardEvents[eventId].oracles.length - 1];
//         delete standardEvents[eventId].oracles[standardEvents[eventId].oracles.length - 1];
//     }


//   function setOracleStakeAt (bytes32 eventId, address oracle, uint stake) onlyAuth {
//         standardEvents[eventId].oracleStakes[oracle] = stake;
//     }

    function checkOracleStatus (address oracle, bytes32 eventId) external view returns (bool) {
        if (eventStructs[eventId].oracleStakes[oracle] == 0) {
            return false;
        } else {
            return true;
        }
    }

}