pragma solidity 0.4.18;
import "./Events.sol";
import "./OracleVerifier.sol";
import "./Rewards.sol";
import "../../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./MvuToken.sol";
import "./Wagers.sol";
import "./Mevu.sol";

contract Oracles is Ownable {
    // Events events;
    // OracleVerifier oracleVerif;
    // Rewards rewards;
    // Admin admin;
    // Wagers wagers;
    // MvuToken mvuToken;
    // Mevu mevu;
    uint oracleServiceFee = 3; //Percent
    mapping (address => mapping(bytes32 => bool)) rewardClaimed;
    mapping (address => bool) private isAuthorized;     

    modifier onlyAuth () {
        require(isAuthorized[msg.sender]);               
                _;
    }  

    struct OracleStruct { 
        bytes32 eventId;
        uint mvuStake;        
        uint winnerVote;
        bool paid;
    }
    
    mapping (address => mapping (bytes32 => OracleStruct)) oracleStructs;    
    mapping (address => bytes32) lastEventOraclized;
    //mapping(address => bytes32[])  oracles;
    //mapping(bytes32 => OracleStruct) oracleStructs;   
    address[] oracleList; // List of people who have ever registered as an oracle    
    address[] correctOracles;
    bytes32[] correctStructs;    
    
    function grantAuthority (address nowAuthorized) onlyOwner {
        isAuthorized[nowAuthorized] = true;
    }

    function removeAuthority (address unauthorized) onlyOwner {
        isAuthorized[unauthorized] = false;
    }

  

    function removeOracle (address oracle, bytes32 eventId) onlyAuth {
        OracleStruct memory thisOracle;
        bytes32 empty;         
        thisOracle = OracleStruct (empty,0,0, false);               
        oracleStructs[oracle][eventId] = thisOracle;    
    }

    function addOracle (bytes32 eventId, uint mvuStake, uint winnerVote) onlyAuth {
        OracleStruct memory thisOracle; 
        thisOracle = OracleStruct (eventId, mvuStake, winnerVote, false);      
        oracleStructs[msg.sender][eventId] = thisOracle;
    }

    

    
    // /** @dev Pay winners of wagers and alter rep of winners and losers, refund both if winner = 0
    //   * @param thisWager the standard wager currently being paid out.
    //   * @param thisEvent the StandardWagerEvent that is associated with thisWager.           
    //   */ 
    // function playerRewards(bytes32 thisWager, bytes32 thisEvent) private {
      
    //     if (events.getWinner(thisEvent) != 0){
    //         if (events.getWinner(thisEvent) == 3){
    //             if (wagers.getMakerWinVote(thisWager) == 3) {
    //                 rewards.addPlayerRep(wagers.getMaker(thisWager), wagers.getWinningValue(thisWager));
    //                 rewards.subPlayerRep(wagers.getTaker(thisWager), wagers.getWinningValue(thisWager));                    
    //             } else {
    //                 rewards.subPlayerRep(wagers.getMaker(thisWager), wagers.getWinningValue(thisWager));
    //                 rewards.addPlayerRep(wagers.getTaker(thisWager), wagers.getWinningValue(thisWager));                    
    //             }              
    //             abortWager(thisWager);
    //         } else {
    //             rewards.addPlayerRep(wagers.getWinner(thisWager), wagers.getWinningValue(thisWager));
    //             rewards.subPlayerRep(wagers.getLoser(thisWager), wagers.getWinningValue(thisWager));                
    //             oracleSettledPayout(thisWager);
    //         }
    //     } else {
    //         abortWager(thisWager);
    //     }         
    // }    

    
    // /** @dev Pays out the wager after oracle settlement.               
    //   * @param wagerId bytes32 id for the wager.         
    //   */
    // function oracleSettledPayout(bytes32 wagerId) private {
        
    //     if (!wagers.getSettled(wagerId)) {            
    //         uint payoutValue = wagers.getWinningValue(wagerId);
    //         uint fee = (payoutValue/100) * oracleServiceFee;
    //         mevu.addMevuBalance(fee/2);            
    //         mevu.addLotteryBalance(fee/12);
    //         payoutValue -= fee;           
    //         uint oracleFee = (fee/12) + (fee/3);
    //         wagers.setSettled(wagerId);
            
    //         if (wagers.getWinner(wagerId) == wagers.getMaker(wagerId)) { // Maker won
    //             rewards.addUnlockedEth(wagers.getMaker(wagerId), payoutValue);
    //             rewards.addEth(wagers.getMaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
           
    //         } else { //Taker won
    //             rewards.addUnlockedEth(wagers.getTaker(wagerId), payoutValue);
    //             rewards.addEth(wagers.getMaker(wagerId),  wagers.getOrigValue(wagerId));          
             
    //         }            
    //         events.addOracleEarnings(wagers.getEventId(wagerId), oracleFee);
    //     }
    // }

    // /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
    //    *  been cancelled, refunds all eth.               
    //    * @param wagerId bytes32 wagerId of the wager to abort.  
    //    */ 
    // function abortWager(bytes32 wagerId) internal {
        
    //     address maker = wagers.getMaker(wagerId);
    //     address taker = wagers.getTaker(wagerId);
    //     wagers.setSettled(wagerId);
    //     rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));       
        
    //     if (taker != address(0)) {         
    //         rewards.addUnlockedEth(wagers.getTaker(wagerId), (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));
    //     } 
            
    // }


//      /** @dev Settle and facilitate payout of wagers needing oracle settlement.           
//       */ 
    //  function oracleSettle() onlyOwner {
     
    //      for (uint a = 0; a < events.getActiveEventsLength(); a++) {
    //          bytes32 eventId = events.getActiveEventId(a);
    //          if (events.getVoteReady(eventId) && !events.getLocked(eventId)) {
    //              if (events.getStandardEventOraclesLength(eventId) >= admin.getMinOracleNum()) { 
    //                 // if (mevu.getStandardEventOracleVotesNum(a) >= mevu.getMinOracleNum()) {     
    //                      //checkStakeEquity(a);
    //                      updateEvent(eventId);                        
    //                      oracleRewards(eventId); 
    //                 // } else {
    //                  //    oracleRedistribute(a);
    //                 // }
    //              } else {
    //                  events.setWinner(eventId, 0);
    //                  events.setLocked(eventId);
    //                 // oracleRefund(eventId);
    //              } 
    //          }
    //      }                 
    //      for (uint i = 0; i < mevu.getOracleQueueLength(); i++) {
    //          bytes32 thisEvent = wagers.getEventId(mevu.getOracleQueueAt(i));      
   
    //          // Determine winner
    //          if (wagers.getMakerChoice(mevu.getOracleQueueAt(i)) == events.getWinner(thisEvent)) {
    //             wagers.setWinner(mevu.getOracleQueueAt(i), wagers.getMaker(mevu.getOracleQueueAt(i)));
    //              wagers.setLoser(mevu.getOracleQueueAt(i), wagers.getTaker(mevu.getOracleQueueAt(i)));
    //          } else {
    //              if (wagers.getTakerChoice(mevu.getOracleQueueAt(i)) == events.getWinner(thisEvent)){ 
    //                 wagers.setWinner(mevu.getOracleQueueAt(i), wagers.getTaker(mevu.getOracleQueueAt(i)));
    //                 wagers.setLoser(mevu.getOracleQueueAt(i), wagers.getMaker(mevu.getOracleQueueAt(i)));
    //              } else {   
    //                  // Tie or no clear winner
    //                  wagers.setWinner(mevu.getOracleQueueAt(i), address(0));
    //                  wagers.setLoser(mevu.getOracleQueueAt(i), address(0));
    //              }
    //          }
    //          // punish loser with bad rep for disagreeing         
    //          // pay and reward winner with rep
    //          playerRewards(mevu.getOracleQueueAt(i), thisEvent);
    //      }     
    //      //Set oracleQueue back to nothing to be re-filled tomorrow.
    //      mevu.deleteOracleQueue();
        
    //  }

    // function oracleRewards(bytes32 eventId) private {
    //     // if winner = 0 it means oracleRefund(thisEvent)
    //     // if winner = 3 it means tie
    //     // reward oracles with eth and mvu proprotionate to their stake as well as adjust reps accourdingly
    //     // oracle struct.paid = true
    //     //pay and reward right oracles the higher fee and rep and mvu from wrong oracles
    //     //punish wrong oracles and those who didn't vote with reputation loss and by losing mvu stake
       

    //     uint stakeForfeit = 0;
    //     delete correctOracles;
    //     delete correctStructs;
    //     uint totalCorrectStake = 0;

      
    //         // find disagreement or non voters 
    //         for (uint i = 0; i < events.getStandardEventOraclesLength(eventId); i++) {                
    //             address thisOracle = events.getStandardEventOracleAt(eventId, i);            
    //             bytes32 thisStruct;
    //             for (uint x = 0; x < getOracleLength(thisOracle); x++){
    //                 if (getEventId(getOracleAt(thisOracle, x)) == eventId) {
    //                     thisStruct = getOracleAt(thisOracle, x);
    //                 }
    //             }
    //             setOraclePaid(thisStruct);              
    //             if (getWinnerVote(thisStruct) == events.getWinner(eventId)) {
    //                 // hooray, was right, reward
    //                 rewards.addOracleRep(thisOracle, getMvuStake(thisStruct));
    //                 correctOracles.push(thisOracle);
    //                 correctStructs.push(thisStruct); 
    //                 totalCorrectStake += getMvuStake(thisStruct);
                                                                    
    //             } else {
    //                 // boo, was wrong or lying, punish
    //                 rewards.subOracleRep(thisOracle, getMvuStake(thisStruct));
    //                 rewards.subMvu(thisOracle, getMvuStake(thisStruct));                         
    //                 stakeForfeit += getMvuStake(thisStruct);                        
    //             }              
    //         }      

    //         for (uint y = 0; y < correctOracles.length; y++){
    //             uint reward = ((getMvuStake(correctStructs[y]) *100)/totalCorrectStake * events.getOracleEarnings(eventId))/100;               
    //             rewards.addEth(correctOracles[y], reward);
    //             rewards.addUnlockedEth(correctOracles[y], reward);                 
    //             uint mvuReward = (getMvuStake(correctStructs[y]) * stakeForfeit)/100;
    //             uint unlockedMvuReward = mvuReward + getMvuStake(correctStructs[y]);
    //             rewards.addUnlockedMvu(correctOracles[y], unlockedMvuReward); 
    //             rewards.addMvu(correctOracles[y], mvuReward);            
                
    //         }             
          
    // }

   
    

     /** @dev Refunds all oracles registered to an event since not enough have registered to vote on the outcome at time of settlement
       *  or because the event has been cancelled.
    
    //   */ 
    // function oracleRefund(bytes32 eventId) private {            
    //     for (uint i = 0; i < events.getStandardEventOraclesLength(eventId); i++) {
            
    //         for (uint x = 0; x < getOracleLength(events.getStandardEventOracleAt(eventId, i)); x++) {
    //             bytes32 thisStruct = getOracleAt(events.getStandardEventOracleAt(eventId, i), x);
    //             if (getEventId(thisStruct) == eventId){

    //                 setOraclePaid(getOracleAt(events.getStandardEventOracleAt(eventId, i), x));

    //                 rewards.addUnlockedMvu(events.getStandardEventOracleAt(eventId, i), getMvuStake(thisStruct));
                  
                                     
    //             }
    //         }
    //     }
    // }
   



    // /** @dev updates a given voteReady event by locking it and determining the winner based on oracle input.               
     
    //   */ 
    // function updateEvent(bytes32 eventId) private {
    //     uint teamOneCount = 0;
    //     uint teamTwoCount = 0;
    //     uint tieCount = 0;     
    //     events.setLocked(eventId);
    //     events.removeEventFromActive(eventId);
    //     for (uint i = 0; i < events.getStandardEventOraclesLength(eventId); i++){
    //         for (uint x =0; x < getOracleLength(events.getStandardEventOracleAt(eventId, i)); x++){
    //             bytes32 thisStruct = getOracleAt(events.getStandardEventOracleAt(eventId, i), x);
    //             if (getEventId(thisStruct) == eventId){
    //                 if (getWinnerVote(thisStruct) == 1){
    //                     teamOneCount++;
    //                 }
    //                 if (getWinnerVote(thisStruct) == 2){
    //                     teamTwoCount++;
    //                 }
    //                 if (getWinnerVote(thisStruct) == 3){
    //                     tieCount++;
    //                 }              
    //             }
    //         }
    //     }
    //     if (teamOneCount > teamTwoCount && teamOneCount > tieCount){
    //        events.setWinner(eventId, 1);
    //     } else {
    //         if (teamTwoCount > teamOneCount && teamTwoCount > tieCount){
    //         events.setWinner(eventId, 2);
    //         } else {
    //             if (tieCount > teamTwoCount && tieCount > teamOneCount){
    //                 events.setWinner(eventId, 3);// Tie
    //             } else {
    //                 events.setWinner(eventId, 0); // No clear winner
    //             }
    //         }
    //     }
                
    // }

    

    function addToOracleList (address oracle) onlyAuth {
        oracleList.push(oracle);
    }  
  

    
    // function setOraclePaid (bytes32 id) internal {
    //     oracleStructs[id].paid = true;
    // }
    
    function setRewardClaimed (address oracle, bytes32 eventId) onlyAuth {
        rewardClaimed[oracle][eventId] = true;
    }

    function setLastEventOraclized (address oracle, bytes32 eventId) onlyAuth {
        lastEventOraclized[oracle] = eventId;
    }

    function getWinnerVote(bytes32 eventId, address oracle)  view returns (uint) {
        return oracleStructs[oracle][eventId].winnerVote;
    }

    function getPaid (bytes32 eventId, address oracle)  view returns (bool) {
        return oracleStructs[oracle][eventId].paid;
    }
   

    function getMvuStake (bytes32 eventId, address oracle) view returns (uint) {
        return oracleStructs[oracle][eventId].mvuStake;
    }    
 
    function getOracleListLength()  view returns (uint) {
        return oracleList.length;
    }

    function getOracleListAt (uint index)  view returns (address) {
        return oracleList[index];
    }

    function getLastEventOraclized (address oracle) view returns (bytes32) {
        return lastEventOraclized[oracle];
    }  

    function getRewardClaimed (address oracle, bytes32 eventId) view returns (bool) {
        return rewardClaimed[oracle][eventId];

    }

}