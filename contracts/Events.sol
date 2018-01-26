pragma solidity ^0.4.18;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Oracles.sol";
import "./Admin.sol";
contract Events is Ownable {

    Admin admin;
    Oracles oracles;

    struct StandardWagerEvent {        
        bytes32 name;       
        bytes32 teamOne;
        bytes32 teamTwo;
        uint startTime; // Unix timestamp
        uint duration; // Seconds
        uint numWagers;
        uint totalAmountBet;
        uint totalAmountResolvedWithoutOracles;          
        uint winner;
        uint loser;
        uint activeEventIndex;
        bytes32[] wagers;           
        bool voteReady;      
        bool locked;       
        bool cancelled;
    }
    mapping (address => bool) private isAuthorized;
    mapping (bytes32 => StandardWagerEvent) standardEvents;
    bytes32[] emptyBytes32Array;
    bytes32[] public activeEvents;
    uint public eventsCount;

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

    function setOraclesContract (address thisAddr) external onlyOwner {
        oracles = Oracles(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }   
       

     /** @dev Creates a new Standard event struct for users to bet on and adds it to the standardEvents mapping.
      * @param name The name of the event to be diplayed.
      * @param startTime The date and time the event begins in the YYYYMMDD9999 format.
      * @param duration The length of the event in seconds.     
      * @param teamOne The name of one of the participants, eg. Toronto Maple Leafs, Georges St-Pierre, Justin Trudeau.
      * @param teamTwo The name of teamOne's opposition.     
      */
    function makeStandardEvent(
        bytes32 id,
        bytes32 name,
        uint startTime,
        uint duration,
        bytes32 teamOne,
        bytes32 teamTwo
    )
        external
        onlyOwner            
    {        
        StandardWagerEvent memory thisEvent;   
        thisEvent = StandardWagerEvent( name,                                        
                                        teamOne,
                                        teamTwo,
                                        startTime,
                                        duration,
                                        0,
                                        0,                                    
                                        0,
                                        0,
                                        0,                                        
                                        activeEvents.length,
                                        emptyBytes32Array,                                                                                                                
                                        false,                                      
                                        false,                                       
                                        false);
        standardEvents[id] = thisEvent;
        eventsCount++;
        activeEvents.push(id);     
    }

    function addResolvedWager (bytes32 eventId, uint value) {
        standardEvents[eventId].totalAmountResolvedWithoutOracles += value;
    }

    function determineEventStage (bytes32 thisEventId, uint lastIndex) onlyAuth {
        
        uint eventEndTime = getStart(thisEventId) + getDuration(thisEventId);
        if (block.timestamp > eventEndTime){
            // Event is over
            if (this.getVoteReady(thisEventId) == false){
                makeVoteReady(thisEventId);
            } else {
                // Go through next active event in array and finalize winners with voteReady events
                decideWinner(thisEventId);
                setLocked(thisEventId);
                removeEventFromActive(thisEventId);
            } 
        }
    }

    function decideWinner (bytes32 eventId) internal {
        //require (oracles.getOracleVotesNum(eventId) >= admin.getMinOracleNum(eventId));
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
                    setWinner(eventId, 0); // No clear winner
                }
            }
        }
    }     


    function removeEventFromActive (bytes32 eventId) { 
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

    function setWinner (bytes32 eventId, uint winner) onlyAuth {
        standardEvents[eventId].winner = winner;        
    }  
    
    function setLocked (bytes32 eventId) onlyAuth {
        standardEvents[eventId].locked = true;        
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

    function getTotalAmountBet (bytes32 eventId) view returns (uint) {
        return standardEvents[eventId].totalAmountBet;
    }

    function getTotalAmountResolvedWithoutOracles (bytes32 eventId) view returns (uint) {
        return standardEvents[eventId].totalAmountResolvedWithoutOracles;
    }

    function getCancelled(bytes32 id) external view returns (bool) {
        return standardEvents[id].cancelled;
    }

    function getStart (bytes32 id) view returns (uint) {
        return standardEvents[id].startTime;
    }

    function getDuration (bytes32 id) view returns (uint) {
        return standardEvents[id].duration;
    }

    function getLocked(bytes32 id) view returns (bool) {
        return standardEvents[id].locked;
    }

    function getWinner (bytes32 id) external view returns (uint) {
        return standardEvents[id].winner;
    }

    function getVoteReady (bytes32 id) external view returns (bool) {
        return standardEvents[id].voteReady;
    }

    function makeVoteReady (bytes32 id) internal {
        standardEvents[id].voteReady = true;
    }

}