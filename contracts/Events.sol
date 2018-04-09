pragma solidity ^0.4.18;
import "./AuthorityGranter.sol";
import "./Oracles.sol";
import "./Admin.sol";
import "./Mevu.sol";
contract Events is AuthorityGranter {

    Admin private admin;
    Oracles private oracles;    
    Mevu private mevu;

    event EventVoteReady(bytes32 eventId);

    struct StandardWagerEvent {         
        bytes32 teamOne;
        bytes32 teamTwo;
        uint startTime; // Unix timestamp
        uint duration; // Seconds
        uint numWagers;
        uint totalAmountBet;
        uint totalAmountResolvedWithoutOracles;          
        uint winner;
        uint makerBond;       
        uint activeEventIndex;
        address maker;
        bytes32[] wagers;                      
        bool locked;       
        bool cancelled;
    }
   
    
    mapping (bytes32 => StandardWagerEvent) private standardEvents;
    bytes32[] private emptyBytes32Array;
    bytes32[] public activeEvents;
    uint public eventsCount;

    function setOraclesContract (address thisAddr) external onlyOwner {
        oracles = Oracles(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    function setMevuContract (address thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }     
       

    /** @dev Creates a new Standard event struct for users to bet on and adds it to the standardEvents mapping.
   
      * @param startTime The timestamp of when the event starts
      * @param duration The length of the event in seconds.     
      * @param teamOne The name of one of the participants, eg. Toronto Maple Leafs, Georges St-Pierre, Justin Trudeau.
      * @param teamTwo The name of teamOne's opposition.     
      */
    function makeStandardEvent(
        bytes32 id,        
        uint startTime,
        uint duration,
        bytes32 teamOne,
        bytes32 teamTwo,
        uint bondValue,
        address maker
    )
        external
        onlyAuth            
    {        
        StandardWagerEvent memory thisEvent;   
        thisEvent = StandardWagerEvent(                                        
                                        teamOne,
                                        teamTwo,
                                        startTime,
                                        duration,
                                        0,
                                        0,                                    
                                        0,
                                        0,
                                        bondValue,                                                                                                              
                                        activeEvents.length,
                                        maker,  
                                        emptyBytes32Array,                                                                                                                                                                                            
                                        false,                                       
                                        false);
        standardEvents[id] = thisEvent;
        eventsCount++;
        activeEvents.push(id);
        //mevu.addEventToIterator();     
    }

    function addResolvedWager (bytes32 eventId, uint value) external onlyAuth {
        standardEvents[eventId].totalAmountResolvedWithoutOracles += value;
    }

    // function determineEventStage (bytes32 thisEventId, uint lastIndex) external onlyAuth {        
    //     uint eventEndTime = getStart(thisEventId) + getDuration(thisEventId);
    //     if (block.timestamp > eventEndTime){
    //         // Event is over
    //         if (getVoteReady(thisEventId) == false){
    //             makeVoteReady(thisEventId);
    //             EventVoteReady(thisEventId);
    //         } else {
    //             // Go through next active event in array and finalize winners with voteReady events
    //             decideWinner(thisEventId);
    //             setLocked(thisEventId);
    //             removeEventFromActive(thisEventId);
    //         } 
    //     }
    // }

    function finalizeEvent(bytes32 eventId) external onlyAuth {
        decideWinner(eventId);
        setLocked(eventId);
        removeEventFromActive(eventId);
    }

    function decideWinner (bytes32 eventId) internal {      
        uint teamOneCount = oracles.getVotesForOne(eventId);
        uint teamTwoCount = oracles.getVotesForTwo(eventId);
        uint tieCount = oracles.getVotesForThree(eventId);    
        if (teamOneCount > teamTwoCount && teamOneCount > tieCount){
           setWinner(eventId, 1);
        } else {
            if (teamTwoCount > teamOneCount && teamTwoCount > tieCount){
            setWinner(eventId, 2);
            } else {
                if (tieCount > teamTwoCount && tieCount > teamOneCount){
                    setWinner(eventId, 3);// Tie
                } else {
                    setWinner(eventId, 4); // No clear winner
                }
            }
        }
          if (oracles.getOracleVotesNum(eventId) < admin.getMinOracleNum(eventId)){
             setWinner(eventId, 4); // No clear winner
         }
    }     


    function removeEventFromActive (bytes32 eventId) internal { 
        uint indexToDelete = standardEvents[eventId].activeEventIndex;
        uint lastItem = activeEvents.length - 1;
        activeEvents[indexToDelete] = activeEvents[lastItem]; // Write over item to delete with last item
        standardEvents[activeEvents[lastItem]].activeEventIndex = indexToDelete; //Point what was the last item to its new spot in array      
        activeEvents.length -- ; // Delete what is now duplicate entry in last spot
    }

    function removeWager (bytes32 eventId, uint value) external onlyAuth {
        standardEvents[eventId].numWagers --;
        standardEvents[eventId].totalAmountBet -= value;
    }   

    function addWager(bytes32 eventId, uint value) external onlyAuth {      
        standardEvents[eventId].numWagers ++;
        standardEvents[eventId].totalAmountBet += value;
    }

    function setWinner (bytes32 eventId, uint winner) public onlyAuth {
        standardEvents[eventId].winner = winner;        
    }  
    
    function setLocked (bytes32 eventId) public onlyAuth {
        standardEvents[eventId].locked = true;        
    }

    function getFinished (bytes32 eventId) external view returns (bool) {
        return (block.timestamp > getEndTime(eventId));
    } 
  
    function getActiveEventId (uint i) external view returns (bytes32) {
        return activeEvents[i];
    }

    function getActiveEventsLength () external view returns (uint) {
        return activeEvents.length;
    } 

    function getStandardEventCount () external view returns (uint) {
        return eventsCount;
    }   

    function getTotalAmountBet (bytes32 eventId) external view returns (uint) {
        return standardEvents[eventId].totalAmountBet;
    }

    function getTotalAmountResolvedWithoutOracles (bytes32 eventId) external view returns (uint) {
        return standardEvents[eventId].totalAmountResolvedWithoutOracles;
    }

    function getCancelled(bytes32 id) external view returns (bool) {
        return standardEvents[id].cancelled;
    }

    function getStart (bytes32 id) public view returns (uint) {
        return standardEvents[id].startTime;
    }

    function getDuration (bytes32 id) public view returns (uint) {
        return standardEvents[id].duration;
    }

    function getEndTime (bytes32 id) public view returns (uint) {
        return (standardEvents[id].startTime + standardEvents[id].duration);
    }

    function getLocked(bytes32 id) public view returns (bool) {
        return standardEvents[id].locked;
    }

    function getMaker (bytes32 eventId) external view returns (address) {
        return standardEvents[eventId].maker;
    }

    function getMakerBond (bytes32 eventId) external view returns (uint) {
        return standardEvents[eventId].makerBond;
    }

    function getTeamOne (bytes32 eventId) external view returns (bytes32) {
        return standardEvents[eventId].teamOne;
    }
    function getTeamTwo (bytes32 eventId) external view returns (bytes32) {
        return standardEvents[eventId].teamTwo;
    }

    function getWinner (bytes32 id) external view returns (uint) {
        return standardEvents[id].winner;
    }

    function getVoteReady (bytes32 id) public view returns (bool) {        //return standardEvents[id].voteReady;
        return ((standardEvents[id].startTime + standardEvents[id].duration) < block.timestamp);
    }

    // function makeVoteReady (bytes32 id) internal {
    //     standardEvents[id].voteReady = true;
    // }

    

}