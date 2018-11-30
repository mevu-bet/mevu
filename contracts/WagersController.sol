
pragma solidity ^0.4.18;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Admin.sol"; 
import "./Wagers.sol"; 
import "./Events.sol";
import "./Rewards.sol";
import "./Mevu.sol";


contract WagersController is Ownable {
    Admin admin;
    Events events;
    Rewards rewards;
    Wagers wagers;
    Mevu mevu;

    event Aborted(bytes32 wagerId);
    event WagerMade(bytes32 id); 
    event WagerTaken(bytes32 id);    
    event VoteSubmit (bytes32 wagerId);
    event Winner (address winner);
  

    modifier eventNotOver(bytes32 eventId){
        require (!events.getVoteReady(eventId));
        _;
    }

    modifier wagerUnlocked (bytes32 wagerId) {
        require (!wagers.getLocked(wagerId));
        _;
    }    

    modifier mustBeTaken (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) != address(0));
        _;
    }   

    modifier checkBalance (uint wagerValue) {
        require (wagerValue >= admin.getMinWagerAmount());
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= wagerValue);
        _;
    }      
    
    modifier notPaused() {
        require (!mevu.getContractPaused());
        _;
    }

    modifier notCancelled(bytes32 eventId) {
        require(!events.getCancelled(eventId));
        _;
    }

    modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == wagers.getMaker(wagerId) || msg.sender == wagers.getTaker(wagerId));        
        _;
    }

    modifier notTaken (bytes32 wagerId) {
        require (wagers.getTaker(wagerId) == address(0));
        _;
    } 

    modifier notMade (bytes32 wagerId) {        
        require (wagers.getMaker(wagerId) == address(0));
        _;
    }     

    function setWagersContract (address thisAddr) external onlyOwner { wagers = Wagers(thisAddr); }

    function setEventsContract (address thisAddr) external onlyOwner { events = Events(thisAddr); }

    function setRewardsContract (address thisAddr) external onlyOwner { rewards = Rewards(thisAddr); }

    function setAdminContract (address thisAddr) external onlyOwner { admin = Admin(thisAddr); }

    function setMevuContract (address thisAddr) external onlyOwner { mevu = Mevu(thisAddr); }

 
    function makeWager(
        bytes32 wagerId,            
        bytes32 eventId,
        uint value,   
        uint odds,
        uint makerChoice
    )    
    notMade(wagerId)
    eventNotOver(eventId)   
    checkBalance(value)
    notPaused
    external
    payable
    {
        require(makerChoice < events.getNumOutcomes(eventId));
      
        // if (makerChoice == 1) {
        //     takerChoice = 2;
        // } else {
        //     takerChoice = 1;
        // }
        uint winningValue = value + (value / (odds/100));       
        wagers.makeWager( 
            wagerId,
            eventId,
            value,
            winningValue,                            
            makerChoice,
           
            odds,
            0,
            0,
            msg.sender);        
        rewards.addEth(msg.sender, msg.value);       
        rewards.subUnlockedEth(msg.sender, (value - msg.value));
        address(mevu).transfer(msg.value);
        emit WagerMade(wagerId);
    }

    function takeWager (
        bytes32 id          
    )
        external
        payable
    {
       
        uint expectedValue = wagers.getOrigValue(id) / (wagers.getOdds(id) / 100);
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= expectedValue);         
        rewards.subUnlockedEth(msg.sender, (expectedValue - msg.value));        
        rewards.addEth(msg.sender, msg.value);
        wagers.setTaker(id, msg.sender);    
        wagers.setLocked(id); 
        uint totalValue = expectedValue + wagers.getOrigValue(id);    
        events.addWager(wagers.getEventId(id), totalValue);    
        address(mevu).transfer(msg.value);
        emit WagerTaken(id);
    }

      /** @dev Enters the makers vote for who actually won after the event is over.               
      * @param wagerId bytes32 id for the wager.
      * @param winnerVote number representing who the creator thinks won the match         
      */
    function submitVote (      
        bytes32 wagerId,
        uint winnerVote
    ) 
        onlyBettor(wagerId)
        notCancelled(wagers.getEventId(wagerId)) 
        notPaused
        external 
    {
      
        require (!wagers.getSettled(wagerId));
        bytes32 eventId = wagers.getEventId(wagerId);
        require(events.getVoteReady(eventId));
        if (msg.sender == wagers.getMaker(wagerId)) {        
            wagers.setMakerWinVote (wagerId, winnerVote);           
        } else {
            wagers.setTakerWinVote (wagerId, winnerVote);            
        }
        uint eventWinner = events.getCurrentWinner(eventId); // Shouldn't matter if bettors agree

        // if (eventWinner != 0 && eventWinner < 3) {
        //     lateSettle(wagerId, eventWinner);
        //     lateSettledPayout(wagerId);                          
        // } else {

        if (block.timestamp > events.getEndTime(eventId) + admin.getOraclePeriod()) {
            
            if (!events.getCancelled(eventId)) { 
                if (events.getThreshold(eventId)){
                    lateSettle(wagerId, eventWinner);
                    lateSettledPayout(wagerId);   
                } else {
                    abortWager(wagerId);
                }
            } 
            //   else {
            //       abortWager(wagerId, wagers.getMaker(wagerId), wagers.getTaker(wagerId),wagers.getOrigValue(wagerId), wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId));
            //   }

        } else {
            if (wagers.getTakerWinVoted(wagerId) && wagers.getMakerWinVoted(wagerId)) {
                // if (wagers.getTakerWinVote(wagerId) == wagers.getMakerWinVote(wagerId)) {
                settle(wagerId, eventId);
               //  } 
                 //else {
        //             if (events.getThreshold(eventId)) {
        //                 lateSettle(wagerId, eventWinner);
        //                 lateSettledPayout(wagerId);   
        //             }
        //         }
            }
        }


        //     if (events.getCancelled(eventId) || events.getWinner(eventId) > 2) {
        //         abortWager(wagerId);                
        //     } else {
        //         if (wagers.getTakerWinVote(wagerId) != 0 && wagers.getMakerWinVote(wagerId) != 0) {
        //             settle(wagerId);                                    
        //         } else {
        //             if (block.timestamp > (events.getEndTime(eventId) + admin.getAbandonPeriod()) && eventWinner == 0) {
        //                 abortWager(wagerId);
        //             }
        //         }
        //     }
        // }

        // If the event is over, and the oracle period is over but it hasn't been finalized, and then a user who has already reported  who wishes to report again does so (despite a front-end warning that
        // it will result in a refund and not winnings if the event hasn't been finalized with a winner. If the event maker cushion is over the front end will give the option of stealing the bond
        // to finalize the event, if they are not an oracle it will detail how to become one in oreder to be abe to make and finalize events) the wager will abort and they will get a refund


        
        emit VoteSubmit(wagerId);               
    }


    /** @dev Settles the wager if both the maker and taker have voted, pays out if they agree, otherwise they need to wait for oracle settlement.               
      * @param wagerId bytes32 id for the wager.         
      */
    function settle(bytes32 wagerId, bytes32 eventId) internal {
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getMaker(wagerId);
        uint origValue = wagers.getOrigValue(wagerId);
        uint payoutValue = wagers.getWinningValue(wagerId); 
        uint fee = (payoutValue/100) * 2; // Sevice fee is 2 percent
        payoutValue -= fee; 
        mevu.addMevuBalance((3*(fee/4)) - (payoutValue/admin.getEventMakerRewardDivider())); 
        mevu.addLotteryBalance(fee/8);
        if (wagers.getMakerWinVote(wagerId) == wagers.getTakerWinVote(wagerId)) {
            if (wagers.getMakerWinVote(wagerId) == wagers.getMakerChoice(wagerId)) {
                wagers.setWinner(wagerId, maker);
                rewards.subEth(maker, origValue);                
                rewards.subEth(taker, wagers.getWinningValue(wagerId) - origValue);
            } else {
                if (wagers.getMakerWinVote(wagerId) == 3) {
                    wagers.setWinner(wagerId, address(0));                    
                } else {
                    rewards.subEth(taker, wagers.getWinningValue(wagerId) - origValue);
                    wagers.setWinner(wagerId, taker);                   
                    rewards.subEth(maker, origValue);
                }
            }
            payout(wagerId, maker, taker, payoutValue);
        } 
        // else {           
        //     if (events.getThreshold(eventId) != 0) { 
        //         lateSettle(wagerId, events.getCurrentWinner(eventId));
        //         lateSettledPayout(wagerId);   

        //     }
        // }
        //     bytes32 eventId = wagers.getEventId(wagerId);
        //     if (oracles.getThreshold(eventId)) {
        //         if (oracles.getCurrentWinner(eventId) == 1 || oracles.getCurrentWinner(eventId) == 2) {
        //             lateSettle(wagerId, oracles.getCurrentWinner(eventId));
        //         }
        //     }
        // }     
    }

    function lateSettle (bytes32 wagerId, uint eventWinner) internal {
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);
        if (wagers.getMakerChoice(wagerId) == eventWinner) {
            wagers.setWinner(wagerId, maker);
            wagers.setLoser(wagerId, taker); 
            emit Winner(maker);              
        } else {     
            wagers.setWinner(wagerId, taker);
            wagers.setLoser(wagerId, maker);     
            emit Winner(taker);  
        } 
       
       
    }

       /** @dev Pays out the wager if both the maker and taker have agreed, otherwise they need to wait for oracle settlement.               
       * @param wagerId bytes32 id for the wager.         
       */
    function payout(bytes32 wagerId, address maker, address taker, uint payoutValue) internal {  
        require(!wagers.getSettled(wagerId));
        wagers.setSettled(wagerId);           
      //  uint origVal =  wagers.getOrigValue(wagerId);
        uint winVal = wagers.getWinningValue(wagerId);
        address winner = wagers.getWinner(wagerId);
            // if (winner == address(0)) { //Tie
            //     mevu.transferEth(maker, origVal);
            //     mevu.transferEth(taker, winVal-origVal);                 
            // } else {            
                events.addResolvedWager(wagers.getEventId(wagerId), winVal);              
                mevu.transferEth(winner, payoutValue);                          
            //}                             
        rewards.addPlayerRep(maker, admin.getPlayerAgreeRepReward());
        rewards.addPlayerRep(taker, admin.getPlayerAgreeRepReward());  
        //WagerSettled(wagerId);    
       emit Winner(winner);           
          
            
    }


    /** @dev Pays out the wager after oracle settlement.               
    * @param wagerId bytes32 id for the wager.         
    */
    function lateSettledPayout(bytes32 wagerId) internal {        
        require(!wagers.getSettled(wagerId));
        wagers.setSettled(wagerId);
        //wagers.setLocked(wagerId);   
        uint origValue = wagers.getOrigValue(wagerId);
        uint winningValue = wagers.getWinningValue(wagerId);
        uint payoutValue = winningValue;         
        uint fee = (payoutValue/100) * 3; //Fee is now 3 percent since oracles were used
        mevu.addMevuBalance((fee/2) -  (payoutValue/admin.getEventMakerRewardDivider()));            
        mevu.addLotteryBalance(fee/12);
        payoutValue -= fee;            
        address maker = wagers.getMaker(wagerId);
        address taker = wagers.getTaker(wagerId);                    
        if (wagers.getWinner(wagerId) == maker) { // Maker won
            //rewards.addUnlockedEth(maker, payoutValue);
            rewards.subEth(maker, origValue);
            mevu.transferEth(maker, payoutValue);    

            //rewards.addEth(maker, payoutValue);
            rewards.addPlayerRep(maker, 1);
            rewards.subPlayerRep(taker, 2);
        } else { //Taker won
            //rewards.addUnlockedEth(taker, payoutValue);
            rewards.subEth(taker, winningValue - origValue);
            //rewards.addEth(taker, payoutValue);
            mevu.transferEth(taker, payoutValue);    
            rewards.addPlayerRep(taker, 1);
            rewards.subPlayerRep(maker, 2);
        }
       
    }

    // function withdraw(
    //     uint eth    
    // )
    //     notPaused   
    //     external         
    // { 
    //     require (rewards.getUnlockedEthBalance(msg.sender) >= eth);
    //     rewards.subUnlockedEth(msg.sender, eth);
    //     rewards.subEth(msg.sender, eth);
    //     //playerFunds -= eth;
    //     mevu.transferEth(msg.sender, eth);         
    // }    

    function cancelRefund(bytes32 wagerId) external {
        require(events.getCancelled(wagers.getEventId(wagerId)));
        require (!wagers.getSettled(wagerId));
        abortWager(wagerId);
    }    

    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
     *  been cancelled, refunds all eth.               
     *  @param wagerId bytes32 wagerId of the wager to abort.  
     */ 
    function abortWager(bytes32 wagerId) internal {

        //require (events.getCancelled(wagers.getEventId(wagerId)));

       address maker = wagers.getMaker(wagerId);
       address taker = wagers.getTaker(wagerId);
        wagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, wagers.getOrigValue(wagerId));    
      
        if (taker != address(0)) {         
            rewards.addUnlockedEth(taker,  (wagers.getWinningValue(wagerId) - wagers.getOrigValue(wagerId)));       
        }   
        emit Aborted(wagerId);          
    }  

}