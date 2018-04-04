pragma solidity ^0.4.18;
// Let anyone make an event that isnt made (at most a week in the future at least not over) by using sha3 of standard naming scheme ex. (nhltormtl20180407) and buying a bonnd

// vote ready will be based on time not a boolean variable
// after 'oracle vote period' the maker wil get his bond money back plus a reward of % of bet profits by finalizing event and removing
// the event from the activeEvents array.

// players can agree anytime after the event ends and can solve disputes anytime after the oracle period ends


import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Admin.sol";
import "./Events.sol";
import "./OracleVerifier.sol";
import "./Mevu.sol";

contract EventsController is Ownable {
    Admin private admin;
    Events private events;
    OracleVerifier private oracleVerif;
    Mevu private mevu;

    modifier isNotMade (bytes32 eventId) {
        require (events.getStart(eventId) == 0);
        _;
    }

    modifier minBond() {
        require (msg.value >= admin.getMinEventBond());
        _;
    }

    modifier notLocked(bytes32 eventId) {
        require (!events.getLocked(eventId));
        _;
    }


    
    modifier onlyVerified() {
        require (oracleVerif.checkVerification(msg.sender));
        _;
    }

    modifier oraclePeriodOver (bytes32 eventId) {
        require(block.timestamp > events.getEndTime(eventId) + admin.getOraclePeriod());
        _;
    }

    function setAdminContract (address thisAddress) external onlyOwner { admin = Admin(thisAddress); }

    function setEventsContract (address thisAddress) external onlyOwner { events = Events(thisAddress); }

    function setOracleVerifierContract (address thisAddress) external onlyOwner { oracleVerif = OracleVerifier(thisAddress); }

    function setMevuContract (address thisAddress) external onlyOwner { mevu = Mevu(thisAddress); }


    function makeEvent (bytes32 id, bytes32 name, uint startTime, uint duration, bytes32 teamOne, bytes32 teamTwo)
        onlyVerified
        isNotMade(id)
        minBond
        external
        payable
    {
        require (startTime > 0 && duration > 0);
        events.makeStandardEvent(id, name, startTime, duration, teamOne, teamTwo, msg.value, msg.sender);
        address(mevu).transfer(msg.value);
    }

   

    // Called by event creator to finalize bet and remove from active array, if not called within win claim period then anyone can call and steal creators bond money
    function finalizeEvent (bytes32 eventId) oraclePeriodOver(eventId) notLocked(eventId) external {
        if (block.timestamp < events.getEndTime(eventId) + admin.getOraclePeriod() + admin.getEventMakerFinalizeCushion()) {
            require(msg.sender == events.getMaker(eventId));
            events.finalizeEvent(eventId);
            mevu.transferEth(msg.sender, events.getMakerBond(eventId) + events.getTotalAmountBet(eventId)/admin.getEventMakerRewardDivider());
        } else  {
            events.finalizeEvent(eventId);
            mevu.transferEth(msg.sender, events.getMakerBond(eventId) + events.getTotalAmountBet(eventId)/admin.getEventMakerRewardDivider());
        }
    }


}
