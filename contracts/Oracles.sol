pragma solidity ^0.5.0;
//import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AuthorityGranter.sol";
import './Events.sol';

contract Oracles is AuthorityGranter {  

    Events events;

    struct OracleStruct { 
        bytes32 eventId;
        uint mvuStake;        
        uint winnerVote;
        bool paid;
    }

    struct EventStruct {
        uint oracleVotes;
        uint totalOracleStake;   
        // uint votesForOne;
        // uint votesForTwo;
        // uint votesForThree;
        uint[] votes;
        // uint stakeForOne;
        // uint stakeForTwo;
        // uint stakeForThree;
        uint[] stakes;
        uint currentWinner;
        mapping (address => uint) oracleStakes;
        address[] oracles;  
       
        bool threshold;
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

    function setEventsContract (address thisAddress) external onlyOwner {
        events = Events(thisAddress);
    }    

    function removeOracle (address oracle, bytes32 eventId) external onlyAuth {
        OracleStruct memory thisOracle;
        bytes32 empty;         
        thisOracle = OracleStruct (empty,0,0, false);               
        oracleStructs[oracle][eventId] = thisOracle;    
    }

    function addOracle (address oracle, bytes32 eventId, uint mvuStake, uint winnerVote, uint minOracleNum) external onlyAuth {
        uint[] memory newVotes = eventStructs[eventId].votes;
        uint[] memory newStakes = eventStructs[eventId].stakes;
        uint numOutcomes = events.getNumOutcomes(eventId) + 1; //because numTeams + 1 means winner could not be decided. A tie is included as a team.
        if (newVotes.length == 0) {
            newVotes = new uint[](numOutcomes); 
            newStakes = new uint[](numOutcomes);   
            for (uint i = 0; i < numOutcomes; i++){
                if (i == winnerVote) {
                    newVotes[i] = 1;
                    newStakes[i] = mvuStake;
                } else {
                    newVotes[i] = 0;
                    newStakes[i] = 0;
                }
            }                    
        } else {
            newVotes[winnerVote] += 1;
            newStakes[winnerVote] += mvuStake;
        }

        OracleStruct memory thisOracle; 
        thisOracle = OracleStruct (eventId, mvuStake, winnerVote, false);      
        oracleStructs[oracle][eventId] = thisOracle;
        // if (winnerVote == 1) {
        //     eventStructs[eventId].votesForOne ++;
        //     eventStructs[eventId].stakeForOne += mvuStake; 
        // }
        // if (winnerVote == 2) {
        //     eventStructs[eventId].votesForTwo ++;
        //     eventStructs[eventId].stakeForTwo += mvuStake; 
        // }
        // if (winnerVote == 3) {
        //     eventStructs[eventId].votesForThree ++;
        //     eventStructs[eventId].stakeForThree += mvuStake; 
        // }
        eventStructs[eventId].votes = newVotes;
        eventStructs[eventId].stakes = newStakes;

        eventStructs[eventId].oracleStakes[oracle] = mvuStake;
        eventStructs[eventId].totalOracleStake += mvuStake;
        eventStructs[eventId].oracleVotes += 1;
        setCurrentWinner(eventId, winnerVote); 

        if (eventStructs[eventId].oracleVotes == minOracleNum) {
            eventStructs[eventId].threshold = true;
            events.setThreshold(eventId);
        }    
    } 

    function setCurrentWinner (bytes32 eventId, uint outcomeJustVotedFor) internal {
        uint currentWinner = eventStructs[eventId].currentWinner;
        // if  (eventStructs[eventId].votesForOne == eventStructs[eventId].votesForTwo) {
        //     eventStructs[eventId].currentWinner = 3;
        //     events.setCurrentWinner(eventId, 3);
        // }
        // if  (eventStructs[eventId].votesForOne > eventStructs[eventId].votesForTwo) {
        //     eventStructs[eventId].currentWinner = 1;
        //     events.setCurrentWinner(eventId, 1);
        // }
        // if  (eventStructs[eventId].votesForTwo > eventStructs[eventId].votesForOne) {
        //     eventStructs[eventId].currentWinner = 2;
        //     events.setCurrentWinner(eventId, 2);
        // }
        // if  (eventStructs[eventId].votesForThree > eventStructs[eventId].votesForOne  &&  eventStructs[eventId].votesForThree > eventStructs[eventId].votesForTwo) {
        //     eventStructs[eventId].currentWinner = 3;
        //     events.setCurrentWinner(eventId, 3);
        // }
        if (currentWinner != outcomeJustVotedFor) {
            if (eventStructs[eventId].votes[outcomeJustVotedFor] > eventStructs[eventId].votes[currentWinner]){
                eventStructs[eventId].currentWinner = outcomeJustVotedFor;
                events.setCurrentWinner(eventId, outcomeJustVotedFor);
            }
        }


    } 


    function addToOracleList (address oracle) external onlyAuth { oracleList.push(oracle); } 

    function setPaid (address oracle, bytes32 eventId) external onlyAuth { oracleStructs[oracle][eventId].paid = true; }  

    function setLastEventOraclized (address oracle, bytes32 eventId) external onlyAuth { lastEventOraclized[oracle] = eventId; }

    function setRefunded (address oracle, bytes32 eventId) external onlyAuth { refundClaimed[oracle][eventId] = true; }

    function setRegistered (address oracle, bytes32 eventId) external onlyAuth { alreadyRegistered[oracle][eventId] = true; }

    function getCurrentWinner (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].currentWinner; } 

    function getRegistered (address oracle, bytes32 eventId) external view returns (bool) { return alreadyRegistered[oracle][eventId]; }

    function getWinnerVote(bytes32 eventId, address oracle) external view returns (uint) { return oracleStructs[oracle][eventId].winnerVote; }

    function getPaid (bytes32 eventId, address oracle) external view returns (bool) { return oracleStructs[oracle][eventId].paid; }

    function getRefunded (bytes32 eventId, address oracle) external view returns (bool) { return refundClaimed[oracle][eventId]; }

    // function getVotesForOne (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForOne; }

    // function getVotesForTwo (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForTwo; }    

    // function getVotesForThree (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].votesForThree; } 

    function getVotesForOutcome (bytes32 eventId, uint outcome) external view returns (uint) { return eventStructs[eventId].votes[outcome]; }

    // function getStakeForOne (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForOne; }

    // function getStakeForTwo (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForTwo; } 

    // function getStakeForThree (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].stakeForThree; }  

    function getStakeForOutcome (bytes32 eventId, uint outcome) external view returns (uint) { return eventStructs[eventId].stakes[outcome]; }

    function getMvuStake (bytes32 eventId, address oracle) external view returns (uint) { return oracleStructs[oracle][eventId].mvuStake; }
   
    function getEventOraclesLength (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].oracles.length; }
    
    function getOracleVotesNum (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].oracleVotes; }   

    function getTotalOracleStake (bytes32 eventId) external view returns (uint) { return eventStructs[eventId].totalOracleStake; }

    function getThreshold (bytes32 eventId) external view returns (bool) { return eventStructs[eventId].threshold; } 
 
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