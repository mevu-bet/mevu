pragma solidity ^0.5.0;
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Admin.sol"; 
import "./CustomWagers.sol"; 
import "./Events.sol";
import "./Rewards.sol";
import "./Mevu.sol";

contract CustomWagersController is Ownable {
    Admin private admin;
    Events private events;
    Rewards private rewards;
    CustomWagers private customWagers;
    Mevu private mevu; 

    event JudgeNeeded (address judge, bytes32 wagerId);
    event WagerMade(bytes32 id); 
    event WagerTaken(bytes32 id);  
    event WagerSettled (bytes32 wagerId);
   
    modifier mustBeTaken (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) != address(0));
        _;
    }
 
    modifier mustBeEnded (bytes32 wagerId) {
        require (customWagers.getEndTime(wagerId) < block.timestamp);
        _;
    }

    modifier notSettled(bytes32 wagerId) {
        require (!customWagers.getSettled(wagerId));
        _;           
    }

    // modifier reportingOver(bytes32 wagerId) {
    //     require (block.timestamp > customWagers.getReportingEndTime(wagerId));
    //     _;
    // }  

    modifier checkBalance (uint wagerValue) {
        require (wagerValue >= admin.getMinWagerAmount());
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= wagerValue);
        _;
    }      
    
    modifier notPaused() {
        require (!mevu.getContractPaused());
        _;
    }

    modifier onlyBettor (bytes32 wagerId) {
        require (msg.sender == customWagers.getMaker(wagerId) || msg.sender == customWagers.getTaker(wagerId));
        _;
    }

    modifier notTaken (bytes32 wagerId) {
        require (customWagers.getTaker(wagerId) == address(0));
        _;
    } 

    modifier notMade (bytes32 wagerId) {        
        require (customWagers.getMaker(wagerId) == address(0));
        _;
    }

    modifier notOver (bytes32 wagerId) {
        require (block.timestamp < customWagers.getEndTime(wagerId));
        _;
    }

    modifier onlyMaker (bytes32 wagerId) {
        require (msg.sender == customWagers.getMaker(wagerId));
        _;
    }

    modifier validVote (uint vote) {
        require (vote == 1 || vote == 2 || vote == 3);
        _;
    }     

    function setCustomWagersContract (address thisAddr) external onlyOwner {
        customWagers = CustomWagers(thisAddr);        
    }

    function setRewardsContract (address thisAddr) external onlyOwner {
        rewards = Rewards(thisAddr);        
    }

    function setAdminContract (address thisAddr) external onlyOwner {
        admin = Admin(thisAddr);
    }

    function setMevuContract (address payable thisAddr) external onlyOwner {
        mevu = Mevu(thisAddr);
    }

    function makeWager (
        bytes32 id,
        uint endTime,
        uint reportingEndTime,
        uint makerChoice,
        uint value,
        uint odds
        
        )
        notMade(id)    
        checkBalance(value)
        notPaused
        external
        payable
    {
        uint takerChoice;
        if (makerChoice == 1) {
          takerChoice = 2;
        } else {
           takerChoice = 1;
        }             
        customWagers.makeWager  ( id,
                            endTime,
                            reportingEndTime,                            
                            value,
                            value + (value / (odds/100)),                            
                            makerChoice,
                            takerChoice,
                            odds,
                            0,
                            0,
                            msg.sender
                            );
        rewards.addEth(msg.sender, msg.value);       
        rewards.subUnlockedEth(msg.sender, (value - msg.value));
        address(mevu).transfer(msg.value);
        emit WagerMade(id);
    }

    function addJudge (bytes32 wagerId, address payable judge) onlyMaker(wagerId) notTaken(wagerId) external {
        customWagers.addJudge(wagerId, judge);
    }


    function takeWager (
        bytes32 id,
        address judge      
    )
        notTaken(id)
        notOver(id)
        external
        payable
    {
        require (judge == customWagers.getJudge(id));
        uint expectedValue = customWagers.getOrigValue(id) / (customWagers.getOdds(id) / 100);
        require (rewards.getUnlockedEthBalance(msg.sender) + msg.value >= expectedValue);         
        rewards.subUnlockedEth(msg.sender, (expectedValue - msg.value));        
        rewards.addEth(msg.sender, msg.value);
        customWagers.setTaker(id, msg.sender);      
        address(mevu).transfer(msg.value);
        emit WagerTaken(id);
    }


    function submitVote (      
        bytes32 wagerId,
        uint winnerVote
    ) 
        onlyBettor(wagerId) 
        mustBeEnded(wagerId)
        notSettled(wagerId)
        notPaused
        external 
    {       
        if (msg.sender == customWagers.getMaker(wagerId)){        
            customWagers.setMakerWinVote (wagerId, winnerVote);
        } else {
            customWagers.setTakerWinVote (wagerId, winnerVote);
        }
        
        if (customWagers.getTakerWinVote(wagerId) != 0 && customWagers.getMakerWinVote(wagerId) != 0) {
            settle(wagerId);            
        }  
    }

    function submitJudgeVote (bytes32 wagerId, uint vote)
        mustBeEnded(wagerId)
        notSettled(wagerId)
        validVote(vote)
        external                       
    {
        require(customWagers.getJudgesVote(wagerId) == 0);
        require(customWagers.getJudge(wagerId) == msg.sender);
        customWagers.setSettled(wagerId);
        customWagers.setJudgesVote(wagerId, vote);      
        uint origValue = customWagers.getOrigValue(wagerId);
        address payable maker = customWagers.getMaker(wagerId);
        address payable taker = customWagers.getTaker(wagerId);
        uint payoutValue = customWagers.getWinningValue(wagerId);
        uint judgeFee = (payoutValue/100);
        uint fee = judgeFee * 3; // Sevice fee is 3 percent, 1 percent goes to judge
        rewards.subEth(maker, origValue);                
        rewards.subEth(taker, payoutValue - origValue);   
        if (vote == 3) {
            tieJudged(msg.sender, maker, taker, origValue, payoutValue);
        } 
        else {
            if (vote == customWagers.getMakerWinVote(wagerId)) {
                customWagers.setWinner(wagerId, maker);                
                mevu.transferEth(maker, payoutValue - fee);   
                rewards.addPlayerRep(maker, admin.getPlayerAgreeRepReward());
                rewards.subPlayerRep(taker, admin.getPlayerDisagreeRepPenalty());    
            } else {               
                customWagers.setWinner(wagerId, taker);                
                mevu.transferEth(taker, payoutValue - fee);   
                rewards.addPlayerRep(taker, admin.getPlayerAgreeRepReward());
                rewards.subPlayerRep(maker, admin.getPlayerDisagreeRepPenalty());
            }     
       
            mevu.addMevuBalance(3* ((fee-judgeFee)/4));
            mevu.addLotteryBalance((fee-judgeFee)/4);
            mevu.transferEth(msg.sender, judgeFee);               
            emit WagerSettled(wagerId);
        }  
    } 

   
    function settle(bytes32 wagerId) internal {
        address payable maker = customWagers.getMaker(wagerId);
        address payable taker = customWagers.getTaker(wagerId);
        uint origValue = customWagers.getOrigValue(wagerId);
        uint payoutValue = customWagers.getWinningValue(wagerId); 
        uint fee = (payoutValue/100) * 2; // Sevice fee is 2 percent
        uint makerWinVote = customWagers.getMakerWinVote(wagerId);
        payoutValue -= fee; 
        mevu.addMevuBalance(3*(fee/4)); 
        mevu.addLotteryBalance(fee/8);
        if (makerWinVote == customWagers.getTakerWinVote(wagerId)) {
            if (makerWinVote == customWagers.getMakerChoice(wagerId)) {
                customWagers.setWinner(wagerId, maker);
                rewards.subEth(maker, origValue);                
                rewards.subEth(taker, customWagers.getWinningValue(wagerId) - origValue);
            } else {
                if (makerWinVote == 3) {
                    customWagers.setWinner(wagerId, address(0));                    
                } else {
                    rewards.subEth(taker, customWagers.getWinningValue(wagerId) - origValue);
                    customWagers.setWinner(wagerId, taker);                   
                    rewards.subEth(maker, origValue);
                }
            }
            payout(wagerId, maker, taker, payoutValue, true);
            emit WagerSettled(wagerId);
        } else {            
            judgeCheck(wagerId);
        }        
    }
    
    function judgeCheck(bytes32 wagerId) internal {
        address payable judge = customWagers.getJudge(wagerId); 
        if (judge != address(0)) {
            emit JudgeNeeded (judge, wagerId);
        } else {
            abortWager(wagerId);
        }
    }

    function tieJudged(address payable judge, address payable maker, address payable taker, uint origValue, uint payoutValue ) internal {
        // give judge 1 percent and reimburse all else
        uint judgeFee = payoutValue/100;
        uint makerRefund = origValue - (payoutValue/200);
        uint takerRefund = (payoutValue-origValue) - (payoutValue/200);
        mevu.transferEth(judge, judgeFee);
        mevu.transferEth(maker, makerRefund);
        mevu.transferEth(taker, takerRefund);
    }

    function finalizeAbandonedBet (bytes32 wagerId) 
        //onlyBettor(wagerId)
        //reportingOver(wagerId)
        external
    {       
        require (block.timestamp > customWagers.getReportingEndTime(wagerId));        
        abortWager(wagerId);                 
    }

    function payout(bytes32 wagerId, address maker, address taker, uint payoutValue, bool agreed) internal {  
        require(!customWagers.getSettled(wagerId));
        
        address payable winner = customWagers.getWinner(wagerId);                      
        mevu.transferEth(winner, payoutValue);              
        if (agreed) {                             
            rewards.addPlayerRep(maker, admin.getPlayerAgreeRepReward());
            rewards.addPlayerRep(taker, admin.getPlayerAgreeRepReward());             
        } else {
            rewards.addPlayerRep(winner, admin.getPlayerAgreeRepReward());
            rewards.subPlayerRep(customWagers.getLoser(wagerId), admin.getPlayerDisagreeRepPenalty());    
        }
    }   

    function withdraw(
        uint eth    
    )
        notPaused   
        external         
    { 
        require (rewards.getUnlockedEthBalance(msg.sender) >= eth);
        rewards.subUnlockedEth(msg.sender, eth);
        rewards.subEth(msg.sender, eth);      
        mevu.transferEth(msg.sender, eth);         
    }        

    /** @dev Aborts a standard wager where the creators disagree and there are not enough oracles or because the event has
     *  been cancelled, refunds all eth.               
     *  @param wagerId bytes32 wagerId of the wager to abort.  
     */ 
    function abortWager(bytes32 wagerId) internal {        
        address maker = customWagers.getMaker(wagerId);
        address taker = customWagers.getTaker(wagerId);
        customWagers.setSettled(wagerId);
        rewards.addUnlockedEth(maker, customWagers.getOrigValue(wagerId));          
        if (taker != address(0)) {         
            rewards.addUnlockedEth(customWagers.getTaker(wagerId), (customWagers.getWinningValue(wagerId) - customWagers.getOrigValue(wagerId)));
        }             
    }   
}