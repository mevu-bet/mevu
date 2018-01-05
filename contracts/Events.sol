pragma solidity ^0.4.18; 
import "./Oracles.sol";
import "./Wagers.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Events is Ownable {
    uint public eventsCount;
    bytes32[] public activeEvents;
       
    Oracles oracles;
    Wagers wagers;
    
    address oraclesAddress;

    struct StandardWagerEvent {        
        bytes32 name;        
        bytes32 eventType;
        bytes32 teamOne;
        bytes32 teamTwo;
        uint startTime; // Unix timestamp
        uint duration; // Seconds
        uint oracleVotes;
        uint totalOracleStake;
        uint oracleEarnings;
        uint winner;
        uint loser;
        uint activeEventIndex;
        bytes32[] wagers;        
        address[] oracles;       
        mapping (address => uint256) oracleStakes;
        bool voteReady;      
        bool locked;       
        bool cancelled;
    }

    mapping (bytes32 => StandardWagerEvent) public standardEvents;
    
    // Empty mappings to instantiate events   
    mapping (address => uint256) oracleStakes;
    address[] emptyAddrArray;
    bytes32[] emptyBytes32Array;

    modifier onlyOracles () {
        require (msg.sender == oraclesAddress);
        _;
    }

    
    modifier onlyAuth () {
        require(
                msg.sender == address(owner) ||
                msg.sender == address(oracles) ||
                msg.sender == address(wagers));
               
                _;
    }

    function setWagersContract (address thisAddr) external onlyOwner {
        wagers = Wagers(thisAddr);        
    }


    function setOraclesContract (address thisAddr) external onlyAuth {
        oracles = Oracles(thisAddr);
        oraclesAddress = thisAddr;
    } 

    function Events () {
        bytes32 empty;
        activeEvents.push(empty);
    }   

  
    /** @dev Creates a new Standard event struct for users to bet on and adds it to the standardEvents mapping.
      * @param name The name of the event to be diplayed.
      * @param startTime The date and time the event begins in the YYYYMMDD9999 format.
      * @param duration The length of the event in seconds.
      * @param eventType The sport or event category, eg. Hockey, MMA, Politics etc...
      * @param teamOne The name of one of the participants, eg. Toronto Maple Leafs, Georges St-Pierre, Justin Trudeau.
      * @param teamTwo The name of teamOne's opposition.     
      */
    function makeStandardEvent(
        bytes32 id,
        bytes32 name,
        uint startTime,
        uint duration,
        bytes32 eventType,
        bytes32 teamOne,
        bytes32 teamTwo
    )
        external
        onlyAuth            
    {        
        StandardWagerEvent memory thisEvent;   
        thisEvent = StandardWagerEvent( name,
                                        eventType,
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
                                        emptyAddrArray,                                                                        
                                        false,                                      
                                        false,                                       
                                        false);
        standardEvents[id] = thisEvent;
        eventsCount++;
        activeEvents.push(id);     
    }

    function updateStandardEvent(
        bytes32 eventId,
        uint newStartTime,
        uint newDuration,
        bytes32 newTeamOne,
        bytes32 newTeamTwo
    ) 
        external 
        onlyAuth 
    {
        standardEvents[eventId].startTime = newStartTime;
        standardEvents[eventId].duration = newDuration;
        standardEvents[eventId].teamOne = newTeamOne;
        standardEvents[eventId].teamTwo = newTeamTwo;       

    }

    function cancelStandardEvent (bytes32 eventId) external onlyAuth {
        standardEvents[eventId].voteReady = true;
        standardEvents[eventId].locked = true;
        standardEvents[eventId].cancelled = true;
        uint indexToDelete standardEvents[eventId].activeEventsIndex;
        uint lastItem = activeEvents.length - 1;
        activeEvents[indexToDelete] = activeEvents[lastItem]; // Write over item to delete with last item
        standardEvents[activeEvents[lastItem]].activeEventsIndex = indexToDelete; //Point what was the last item to its new spot in array      
        activeEvents.length - ; // Delete what is now duplicate entry in last spot
    }

     /** @dev loops through all active events and sets an event to voteReady = true if it is over but not settled.      
      */
    function voteReady() external onlyAuth {   
        uint blockTime = block.timestamp;
        uint eventEndTime;
        for (uint i = 0; i < activeEvents.length; i++){
            bytes32 thisEvent = activeEvents[i];
            eventEndTime = this.getStart(thisEvent) + this.getDuration(thisEvent);       
            if (blockTime > eventEndTime){
                // Event is over
                if (this.getVoteReady(thisEvent) == false){
                    makeVoteReady(thisEvent);
                }
            }
        }
    }

    function addOracle (bytes32 eventId, address oracle, uint mvuStake) onlyOracles {
        standardEvents[eventId].oracles.push(oracle); 
        standardEvents[eventId].oracleStakes[oracle] = mvuStake;
        standardEvents[eventId].totalOracleStake += mvuStake;
        standardEvents[eventId].oracleVotes += 1;                          
    } 

    function removeEventFromActive (bytes32 eventId) external onlyAuth { 
        uint indexToDelete standardEvents[eventId].activeEventsIndex;
        uint lastItem = activeEvents.length - 1;
        activeEvents[indexToDelete] = activeEvents[lastItem]; // Write over item to delete with last item
        standardEvents[activeEvents[lastItem]].activeEventsIndex = indexToDelete; //Point what was the last item to its new spot in array      
        activeEvents.length - ; // Delete what is now duplicate entry in last spot
    }   

    function addOracleEarnings (bytes32 id, uint amount) external onlyAuth {
        standardEvents[id].oracleEarnings += amount;
    }

    function addWager(bytes32 eventId, bytes32 wagerId) external onlyAuth {
        standardEvents[eventId].wagers.push(wagerId);
    }

    function subTotalOracleStake (bytes32 eventId, uint amount) external onlyAuth {
        standardEvents[eventId].totalOracleStake -= amount;
        standardEvents[eventId].oracleVotes -= 1;
    }

    function removeOracleFromEvent (bytes32 eventId, uint oracle) external onlyAuth {
        standardEvents[eventId].oracles[oracle] = standardEvents[eventId].oracles[standardEvents[eventId].oracles.length - 1];
        delete standardEvents[eventId].oracles[standardEvents[eventId].oracles.length - 1];
    }

      function setWinner (bytes32 eventId, uint winner) external onlyAuth {
        standardEvents[eventId].winner = winner;        
    }  
    
    function setLocked (bytes32 eventId) external onlyAuth {
        standardEvents[eventId].locked = true;        
    }

    function setOracleStakeAt (bytes32 eventId, address oracle, uint stake) {
        standardEvents[eventId].oracleStakes[oracle] = stake;
    }

    function getActiveEventId (uint i) external view returns (bytes32) {
        return activeEvents[i];
    }

    function getActiveEventsLength () external view returns (uint) {
        return activeEvents.length;
    }

    function getOracleStakeAt (bytes32 eventId, address oracle) constant returns (uint) {
        return standardEvents[eventId].oracleStakes[oracle];
    }

    function getStandardEventCount () external view returns (uint) {
        return eventsCount;
    }    

    function getStandardEventOraclesLength (bytes32 eventId) external view returns (uint) {
        return standardEvents[eventId].oracles.length;
    }
    
    function getStandardEventOracleVotesNum (bytes32 eventId) external view returns (uint) {
        return standardEvents[eventId].oracleVotes;
    }

    function getStandardEventOracleAt (bytes32 eventId, uint index) external view returns (address) {
        return standardEvents[eventId].oracles[index];
    }

    function getOracleEarnings (bytes32 eventId) external view returns (uint) {
        return standardEvents[eventId].oracleEarnings;
    }

    function getTotalOracleStake (bytes32 eventId) external view returns (uint256) {
        return standardEvents[eventId].totalOracleStake;
    }


    function getCancelled(bytes32 id) external view returns (bool) {
        return standardEvents[id].cancelled;
    }

    function getStart (bytes32 id) external view returns (uint) {
        return standardEvents[id].startTime;
    }

    function getDuration (bytes32 id) external view returns (uint) {
        return standardEvents[id].duration;
    }

    function getLocked(bytes32 id) external view returns (bool) {
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