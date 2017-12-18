pragma solidity 0.4.18;
import "./Events.sol";
import "./OracleVerifier.sol";
import "./Rewards.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./MvuToken.sol";
import "./Wagers.sol";
import "./Mevu.sol";

contract Oracles is Ownable {
    Events events;
    OracleVerifier oracleVerif;
    Rewards rewards;
    Admin admin;
    Wagers wagers;
    MvuToken mvuToken;
    Mevu mevu;
        uint oracleServiceFee = 3; //Percent

    modifier eventUnlocked(bytes32 eventId){
        require (!events.getLocked(eventId));
        _;
    }

    modifier onlyVerified() {
        require (oracleVerif.checkVerification(msg.sender));
        _;
    }

    modifier mustBeVoteReady(bytes32 eventId) {
        require (events.getVoteReady(eventId));
        _;           
    }  

     modifier onlyAuth () {
        require(msg.sender == address(admin) ||
              
                
                msg.sender == address(wagers));
                _;
    }

    
     

    


    struct OracleStruct {
        bytes32 oracleId;
        bytes32 eventId;
        uint mvuStake;        
        uint winnerVote;
        bool paid;
    }
    mapping(address => bool) beenAnOracle;
    mapping(address => bytes32[])  oracles;
    mapping(bytes32 => OracleStruct) oracleStructs;   
    address[]  oracleList; // List of people who have ever registered as an oracle
    
 address[] correctOracles;
    bytes32[] correctStructs;    
    
    function setEventsContract (address thisAddr) external onlyOwner {
        events = Events(thisAddr);        
    }

    function setOracleVerifContract (address thisAddr) external onlyOwner {
        oracleVerif  = OracleVerifier(thisAddr);
    }

    function setRewardsContract   (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    function setMvuTokenContract (address thisAddr) external onlyOwner {
        mvuToken = MvuToken(thisAddr);
    }

    function setMevuContract (address thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }


    function removeOracle (address oracle, bytes32 eventId, bytes32 oracleId) onlyOwner {
        OracleStruct memory thisOracle;         
        thisOracle = OracleStruct (0,0,0,0, false);               
        oracleStructs[oracleId] = thisOracle;    
    }

  

    //  /** @dev Registers a user as an Oracle for the chosen event. Before being able to register the user must
    //   * allow the contract to move their MVU through the Token contract.      
    //   * @param oracleId bytes32 id for the oracle mapping to get struct with info.            
    //   * @param eventId int id for the standard event the oracle is registered for.
    //   * @param mvuStake Amount of mvu (in lowest base unit) staked.         
    //   */
      function registerOracle (        
      bytes32 oracleId,
        bytes32 eventId,
          uint mvuStake,
          uint winnerVote
      ) 
          eventUnlocked(eventId) 
          onlyVerified          
          mustBeVoteReady(eventId) 
      {
          //require (keccak256(strConcat(addrToString(msg.sender),  bytes32ToString(eventId))) == oracleId);       
          require(mvuStake >= admin.getMinOracleStake());
          require(winnerVote == 1 || winnerVote == 2 || winnerVote == 3); 
           
   
          if (getBeenOracle(msg.sender) == false) {
                addToOracleList(msg.sender);
                setBeenOracle(msg.sender);
          }
          transferTokensToOwner(msg.sender, mvuStake);
    
        if (getMvuStake(oracleId) == 0) {       
            OracleStruct memory thisOracle; 
            thisOracle = OracleStruct (oracleId, eventId, mvuStake, winnerVote, false);
            oracles[msg.sender].push(oracleId);
            oracleStructs[oracleId] = thisOracle;
            rewards.addMvu(msg.sender, mvuStake);
            events.addOracle(eventId, msg.sender, mvuStake);
        }   
              
    }

    
    /** @dev Pay winners of wagers and alter rep of winners and losers, refund both if winner = 0
      * @param thisWager the standard wager currently being paid out.
      * @param thisEvent the StandardWagerEvent that is associated with thisWager.           
      */ 
    function playerRewards(bytes32 thisWager, bytes32 thisEvent) private {
      
        if (events.getWinner(thisEvent) != 0){
            if (events.getWinner(thisEvent) == 3){
                if (wagers.getMakerWinVote(thisWager) == 3) {
                    rewards.addPlayerRep(wagers.getMaker(thisWager), wagers.getWinningValue(thisWager));
                    rewards.subPlayerRep(wagers.getTaker(thisWager), wagers.getWinningValue(thisWager));                    
                } else {
                    rewards.subPlayerRep(wagers.getMaker(thisWager), wagers.getWinningValue(thisWager));
                    rewards.addPlayerRep(wagers.getTaker(thisWager), wagers.getWinningValue(thisWager));                    
                }              
                abortWager(thisWager);
            } else {
                rewards.addPlayerRep(wagers.getWinner(thisWager), wagers.getWinningValue(thisWager));
                rewards.subPlayerRep(wagers.getLoser(thisWager), wagers.getWinningValue(thisWager));                
                oracleSettledPayout(thisWager);
            }
        } else {
            abortWager(thisWager);
        }         
    }    

    
    /** @dev Pays out the wager after oracle settlement.               
      * @param wagerId bytes32 id for the wager.         
      */
    function oracleSettledPayout(bytes32 wagerId) private {
        
        if (!wagers.getSettled(wagerId)) {            
            uint payoutValue = wagers.getWinningValue(wagerId);
            uint fee = (payoutValue/100) * oracleServiceFee;
            mevu.addMevuBalance(fee/2);            
            mevu.addLotteryBalance(fee/12);
            payoutValue -= fee;           
            uint oracleFee = (fee/12) + (fee/3);
            wagers.setSettled(wagerId);
            
            if (wagers.getWinner(wagerId) == wagers.getMaker(wagerId)) { // Maker won
                rewards.addUnlockedEth(wagers.getMaker(wagerId), payoutValue);
                rewards.addEth(wagers.getMaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
           
            } else { //Taker won
                rewards.addUnlockedEth(wagers.getTaker(wagerId), payoutValue);
                rewards.addEth(wagers.getMaker(wagerId),  wagers.getOrigValue(wagerId));          
             
            }            
            events.addOracleEarnings(wagers.getEventId(wagerId), oracleFee);
        }
    }

    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
       *  been cancelled, refunds all eth.               
       * @param wagerId bytes32 wagerId of the wager to abort.  
       */ 
    function abortWager(bytes32 wagerId) internal {
        
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));       
        
        if (taker != address(0)) {         
            rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
        } 
            
    }


//      /** @dev Settle and facilitate payout of wagers needing oracle settlement.           
//       */ 
     function oracleSettle() onlyOwner {
     
         for (uint a = 0; a < events.getActiveEventsLength(); a++) {
             bytes32 eventId = events.getActiveEventId(a);
             if (events.getVoteReady(eventId) && !events.getLocked(eventId)) {
                 if (events.getStandardEventOraclesLength(eventId) >= admin.getMinOracleNum()) { 
                    // if (mevu.getStandardEventOracleVotesNum(a) >= mevu.getMinOracleNum()) {     
                         //checkStakeEquity(a);
                         updateEvent(eventId);                        
                         oracleRewards(eventId); 
                    // } else {
                     //    oracleRedistribute(a);
                    // }
                 } else {
                     events.setWinner(eventId, 0);
                     events.setLocked(eventId);
                    // oracleRefund(eventId);
                 } 
             }
         }                 
         for (uint i = 0; i < mevu.getOracleQueueLength(); i++) {
             bytes32 thisEvent = wagers.getEventId(mevu.getOracleQueueAt(i));      
   
             // Determine winner
             if (wagers.getMakerChoice(mevu.getOracleQueueAt(i)) == events.getWinner(thisEvent)) {
                wagers.setWinner(mevu.getOracleQueueAt(i), wagers.getMaker(mevu.getOracleQueueAt(i)));
                 wagers.setLoser(mevu.getOracleQueueAt(i), wagers.getTaker(mevu.getOracleQueueAt(i)));
             } else {
                 if (wagers.getTakerChoice(mevu.getOracleQueueAt(i)) == events.getWinner(thisEvent)){ 
                    wagers.setWinner(mevu.getOracleQueueAt(i), wagers.getTaker(mevu.getOracleQueueAt(i)));
                    wagers.setLoser(mevu.getOracleQueueAt(i), wagers.getMaker(mevu.getOracleQueueAt(i)));
                 } else {   
                     // Tie or no clear winner
                     wagers.setWinner(mevu.getOracleQueueAt(i), address(0));
                     wagers.setLoser(mevu.getOracleQueueAt(i), address(0));
                 }
             }
             // punish loser with bad rep for disagreeing         
             // pay and reward winner with rep
             playerRewards(mevu.getOracleQueueAt(i), thisEvent);
         }     
         //Set oracleQueue back to nothing to be re-filled tomorrow.
         mevu.deleteOracleQueue();
        
     }

    function oracleRewards(bytes32 eventId) private {
        // if winner = 0 it means oracleRefund(thisEvent)
        // if winner = 3 it means tie
        // reward oracles with eth and mvu proprotionate to their stake as well as adjust reps accourdingly
        // oracle struct.paid = true
        //pay and reward right oracles the higher fee and rep and mvu from wrong oracles
        //punish wrong oracles and those who didn't vote with reputation loss and by losing mvu stake
       

        uint stakeForfeit = 0;
        delete correctOracles;
        delete correctStructs;
        uint totalCorrectStake = 0;

      
            // find disagreement or non voters 
            for (uint i = 0; i < events.getStandardEventOraclesLength(eventId); i++) {                
                address thisOracle = events.getStandardEventOracleAt(eventId, i);            
                bytes32 thisStruct;
                for (uint x = 0; x < getOracleLength(thisOracle); x++){
                    if (getEventId(getOracleAt(thisOracle, x)) == eventId) {
                        thisStruct = getOracleAt(thisOracle, x);
                    }
                }
                setOraclePaid(thisStruct);              
                if (getWinnerVote(thisStruct) == events.getWinner(eventId)) {
                    // hooray, was right, reward
                    rewards.addOracleRep(thisOracle, getMvuStake(thisStruct));
                    correctOracles.push(thisOracle);
                    correctStructs.push(thisStruct); 
                    totalCorrectStake += getMvuStake(thisStruct);
                                                                    
                } else {
                    // boo, was wrong or lying, punish
                    rewards.subOracleRep(thisOracle, getMvuStake(thisStruct));
                    rewards.subMvu(thisOracle, getMvuStake(thisStruct));                         
                    stakeForfeit += getMvuStake(thisStruct);                        
                }              
            }      

            for (uint y = 0; y < correctOracles.length; y++){
                uint reward = ((getMvuStake(correctStructs[y]) *100)/totalCorrectStake * events.getOracleEarnings(eventId))/100;               
                rewards.addEth(correctOracles[y], reward);
                rewards.addUnlockedEth(correctOracles[y], reward);                 
                uint mvuReward = (getMvuStake(correctStructs[y]) * stakeForfeit)/100;
                uint unlockedMvuReward = mvuReward + getMvuStake(correctStructs[y]);
                rewards.addUnlockedMvu(correctOracles[y], unlockedMvuReward); 
                rewards.addMvu(correctOracles[y], mvuReward);            
                
            }             
          
    }
    

     /** @dev Refunds all oracles registered to an event since not enough have registered to vote on the outcome at time of settlement
       *  or because the event has been cancelled.
    
      */ 
    function oracleRefund(bytes32 eventId) private {            
        for (uint i = 0; i < events.getStandardEventOraclesLength(eventId); i++) {
            
            for (uint x = 0; x < getOracleLength(events.getStandardEventOracleAt(eventId, i)); x++) {
                bytes32 thisStruct = getOracleAt(events.getStandardEventOracleAt(eventId, i), x);
                if (getEventId(thisStruct) == eventId){

                    setOraclePaid(getOracleAt(events.getStandardEventOracleAt(eventId, i), x));

                    rewards.addUnlockedMvu(events.getStandardEventOracleAt(eventId, i), getMvuStake(thisStruct));
                  
                                     
                }
            }
        }
    }



    /** @dev updates a given voteReady event by locking it and determining the winner based on oracle input.               
     
      */ 
    function updateEvent(bytes32 eventId) private {
        uint teamOneCount = 0;
        uint teamTwoCount = 0;
        uint tieCount = 0;     
        events.setLocked(eventId);
        events.removeEventFromActive(eventId);
        for (uint i = 0; i < events.getStandardEventOraclesLength(eventId); i++){
            for (uint x =0; x < getOracleLength(events.getStandardEventOracleAt(eventId, i)); x++){
                bytes32 thisStruct = getOracleAt(events.getStandardEventOracleAt(eventId, i), x);
                if (getEventId(thisStruct) == eventId){
                    if (getWinnerVote(thisStruct) == 1){
                        teamOneCount++;
                    }
                    if (getWinnerVote(thisStruct) == 2){
                        teamTwoCount++;
                    }
                    if (getWinnerVote(thisStruct) == 3){
                        tieCount++;
                    }              
                }
            }
        }
        if (teamOneCount > teamTwoCount && teamOneCount > tieCount){
           events.setWinner(eventId, 1);
        } else {
            if (teamTwoCount > teamOneCount && teamTwoCount > tieCount){
            events.setWinner(eventId, 2);
            } else {
                if (tieCount > teamTwoCount && tieCount > teamOneCount){
                    events.setWinner(eventId, 3);// Tie
                } else {
                    events.setWinner(eventId, 0); // No clear winner
                }
            }
        }
                
    }

    

    function addToOracleList (address oracle) internal {
        oracleList.push(oracle);
    }

    function transferTokensToOwner (address oracle, uint mvuStake) internal {
        mvuToken.transferFrom(oracle, address(this.owner), mvuStake);       
    }
  

    
    function setOraclePaid (bytes32 id) internal {
        oracleStructs[id].paid = true;
    }

    function setBeenOracle (address oracle) internal {
        beenAnOracle[oracle] = true;
    }

    function getWinnerVote(bytes32 id)  view returns (uint) {
        return oracleStructs[id].winnerVote;
    }

    function getPaid (bytes32 id)  view returns (bool) {
        return oracleStructs[id].paid;
    }

    function getEventId(bytes32 oracleId)  view returns (bytes32) {
        return oracleStructs[oracleId].eventId;
    }

    function getMvuStake (bytes32 id) view returns (uint) {
        return oracleStructs[id].mvuStake;
    }

   

    function getBeenOracle (address oracle) view returns (bool) {
        return beenAnOracle[oracle];
    }
    
    function getOracleAt (address oracle, uint index)  view returns (bytes32) {
        return oracles[oracle][index];
    }   
     
     function getOracleLength(address oracle)  view returns (uint) {
         bytes32[] memory thisOracle = oracles[oracle];
         return thisOracle.length;
    }

    function getOracleListLength()  view returns (uint) {
        return oracleList.length;
    }

    function getOracleListAt (uint index)  view returns (address) {
        return oracleList[index];
    }
  

}